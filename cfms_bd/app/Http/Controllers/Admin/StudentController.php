<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Imports\StudentImport;
use App\Models\Student;
use App\Models\Program;
use App\Models\Batch;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Validators\ValidationException;


class StudentController extends Controller
{
    /**
     * GET: Fetch all students with their Program, Batch and Enrollments (Section).
     */
    public function index()
    {
        try {
            // ✨ FIX: 'enrollments' relation add kiya taake Flutter mein Section show ho sake
            $students = Student::with(['program:id,program_name', 'batch:id,batch_name', 'enrollments'])->latest()->get();

            return response()->json([
                'success' => true,
                'message' => 'Students retrieved successfully.',
                'data'    => $students
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve students.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * GET: Fetch a single student's details for editing.
     */
    public function show($id)
    {
        try {
            // ✨ FIX: Yahan bhi 'enrollments' add kiya
            $student = Student::with(['program:id,program_name', 'batch:id,batch_name', 'enrollments'])->find($id);

            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student not found.'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Student details retrieved successfully.',
                'data'    => $student
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve student details.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * PUT: Update student details from the screen.
     */
    public function update(Request $request, $id)
    {
        $student = Student::find($id);

        if (!$student) {
            return response()->json([
                'success' => false,
                'message' => 'Student not found.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'std_name'     => 'required|string|max:255',
            'reg_no'       => 'required|string|max:100|unique:students,reg_no,' . $id,
            'program_name' => 'required|string|exists:programs,program_name',
            'batch_name'   => 'required|string|exists:batches,batch_name',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $validator->errors()->all()
            ], 422);
        }

        $programId = Program::where('program_name', trim($request->program_name))->value('id');
        $batchId = Batch::where('batch_name', trim($request->batch_name))->value('id');

        try {
            $student->update([
                'std_name'   => trim($request->std_name),
                'reg_no'     => trim($request->reg_no),
                'program_id' => $programId,
                'batch_id'   => $batchId,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Student details updated successfully.',
                // ✨ FIX: Yahan bhi 'enrollments' add kiya taake update hone ke baad bhi grid theek rahay
                'data'    => $student->load(['program:id,program_name', 'batch:id,batch_name', 'enrollments'])
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update student.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * DELETE: Remove a student record from the system.
     */
    public function destroy($id)
    {
        try {
            $student = Student::find($id);

            if (!$student) {
                return response()->json([
                    'success' => false,
                    'message' => 'Student not found.'
                ], 404);
            }

            $student->delete();

            return response()->json([
                'success' => true,
                'message' => 'Student deleted successfully.'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete student.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * POST: Bulk import students via Excel/CSV file.
     */
    public function import(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|mimes:xlsx,xls,csv,txt|max:10240',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'File validation failed.',
                'errors'  => $validator->errors()->all()
            ], 422);
        }

        try {
            Excel::import(new StudentImport, $request->file('file'));

            return response()->json([
                'success' => true,
                'message' => 'All students have been imported successfully.'
            ], 200);

        } catch (ValidationException $e) {
            $failures = $e->failures();
            $errorDetails = [];

            foreach ($failures as $failure) {
                $errorDetails[] = "Row " . $failure->row() . ": " . implode(', ', $failure->errors());
            }

            return response()->json([
                'success' => false,
                'message' => 'Data validation errors occurred during import.',
                'errors'  => $errorDetails
            ], 422);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Backend Error: ' . $e->getMessage(), 
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}