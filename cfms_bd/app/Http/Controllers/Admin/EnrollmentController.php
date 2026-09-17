<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Enrollment;
use App\Imports\EnrollmentImport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Facades\Excel;
use Exception;

class EnrollmentController extends Controller
{
    /**
     * Display structural data matrices grid mappings context.
     */
    public function index()
    {
        try {
            $enrollments = Enrollment::with([
                'student.program.department',
                'courseOffered.course',
                'courseOffered.session'
            ])->get();

            return response()->json([
                'success' => true,
                'data'    => $enrollments
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve structural enrollment matrices.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Handle multi-row spreadsheet uploads dynamically.
     */
    public function import(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|mimes:xlsx,xls,csv|max:10240',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Document parsing criteria constraint mismatch.',
                'errors'  => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            Excel::import(new EnrollmentImport, $request->file('file'));
            
            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Enrollment ledger structural parameters populated successfully.'
            ], 200);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Spreadsheet ledger processing engine execution fault.',
                'error'   => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Perform inline grid update operations safely.
     */
    public function update(Request $request, $id)
    {
        $enrollment = Enrollment::find($id);

        if (!$enrollment) {
            return response()->json([
                'success' => false,
                'message' => 'Target enrollment entry footprint not found.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'student_id'        => 'required|exists:students,id',
            'course_offered_id' => 'required|exists:course_offered,id',
            'section'           => 'nullable|string|max:191',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Provided structural foreign keys fail internal sanity parameters.',
                'errors'  => $validator->errors()
            ], 422);
        }

        // Prevent compound uniqueness conflicts from rendering invalid entries
        $duplicateCheck = Enrollment::where('student_id', $request->student_id)
            ->where('course_offered_id', $request->course_offered_id)
            ->where('id', '!=', $id)
            ->exists();

        if ($duplicateCheck) {
            return response()->json([
                'success' => false,
                'message' => 'This configuration constraints duplicate an existing student enrollment profile.'
            ], 409);
        }

        try {
            $enrollment->update([
                'student_id'        => $request->student_id,
                'course_offered_id' => $request->course_offered_id,
                'section'           => $request->section,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Enrollment parameter details updated correctly.',
                'data'    => $enrollment->load(['student.program', 'courseOffered.course', 'courseOffered.session'])
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Database persistence execution trace failed.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Terminate enrollment records safely.
     */
    public function destroy($id)
    {
        try {
            $enrollment = Enrollment::find($id);

            if (!$enrollment) {
                return response()->json([
                    'success' => false,
                    'message' => 'Requested target row instance does not exist within the scope.'
                ], 404);
            }

            $enrollment->delete();

            return response()->json([
                'success' => true,
                'message' => 'Target student enrollment dropped from database context logs.'
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Log context dropping sequence failed.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}