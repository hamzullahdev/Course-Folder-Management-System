<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CourseOffered;
use App\Imports\CourseOfferedImport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Facades\Excel;
use Exception;

class CourseOfferedController extends Controller
{
    /**
     * Display a listing of offered courses with nested relationships.
     */
    public function index()
    {
        try {
            $offeredCourses = CourseOffered::with(['course.program.department', 'session'])->get();

            return response()->json([
                'success' => true,
                'data'    => $offeredCourses
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch offered courses data.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Handle bulk Excel data importing operations.
     */
    public function import(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|mimes:xlsx,xls,csv|max:10240',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error occur.',
                'errors'  => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            Excel::import(new CourseOfferedImport, $request->file('file'));
            
            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Courses offered data imported successfully.'
            ], 200);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Import process failed.',
                'error'   => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Update the course offering timeline configuration parameters.
     */
    public function update(Request $request, $id)
    {
        $offeredCourse = CourseOffered::find($id);

        if (!$offeredCourse) {
            return response()->json([
                'success' => false,
                'message' => 'Offered course record not found.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'course_id'  => 'required|exists:courses,id',
            'session_id' => 'required|exists:sessions,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid relational keys supplied.',
                'errors'  => $validator->errors()
            ], 422);
        }

        // Check for compound unique constraint validation before save operation executes
        $duplicateCheck = CourseOffered::where('course_id', $request->course_id)
            ->where('session_id', $request->session_id)
            ->where('id', '!=', $id)
            ->exists();

        if ($duplicateCheck) {
            return response()->json([
                'success' => false,
                'message' => 'This specific course is already offered in the selected academic session.'
            ], 409);
        }

        try {
            $offeredCourse->update([
                'course_id'  => $request->course_id,
                'session_id' => $request->session_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Offered course profile updated successfully.',
                'data'    => $offeredCourse->load(['course.program', 'session'])
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Update runtime operation execution failed.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified course offering assignment configuration structure.
     */
    public function destroy($id)
    {
        try {
            $offeredCourse = CourseOffered::find($id);

            if (!$offeredCourse) {
                return response()->json([
                    'success' => false,
                    'message' => 'Target record context matching ID does not exist.'
                ], 404);
            }

            $offeredCourse->delete();

            return response()->json([
                'success' => true,
                'message' => 'Offered course structural assignment dropped successfully.'
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Deletion routine execution encountered exceptions.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}