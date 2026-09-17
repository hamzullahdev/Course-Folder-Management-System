<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Course;
use App\Imports\CoursesImport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Facades\Excel;
use Maatwebsite\Excel\Validators\ValidationException;

class CourseController extends Controller
{
    /**
     * 1. GET ALL COURSES (With Program Scope)
     * URL: GET /api/admin/course
     */
    public function index()
    {
        try {
            $courses = Course::with('program')->latest()->get();
            return response()->json($courses, 200);
        } catch (\Exception $e) {
            return response()->json(['message' => 'There was an error fetching the courses: ' . $e->getMessage()], 500);
        }
    }

    /**
     * 2. STORE SINGLE COURSE MANUALLY
     * URL: POST /api/admin/course
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'course_name' => 'required|string|max:255',
            'course_code' => 'required|string|unique:courses,course_code',
            'short_name'  => 'required|string|max:50',
            'credit_hrs'  => 'required|string',
            'program_id'  => 'required|exists:programs,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $course = Course::create($request->all());
            return response()->json([
                'message' => 'Course manually created successfully',
                'data' => $course->load('program')
            ], 201);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * 3. EXCEL BULK DATA IMPORT
     * URL: POST /api/admin/course/import
     */
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,xls,csv|max:2048',
        ]);

        try {
            Excel::import(new CoursesImport, $request->file('file'));
            return response()->json(['message' => 'Excel dataset records imported successfully'], 200);
        } catch (ValidationException $e) {
            $failures = $e->failures();
            $errorDetails = [];
            foreach ($failures as $failure) {
                $errorDetails[] = [
                    'row' => $failure->row(),
                    'attribute' => $failure->attribute(),
                    'errors' => $failure->errors(),
                ];
            }
            return response()->json([
                'message' => 'Validation failed in Excel file.',
                'errors' => $errorDetails
            ], 422);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Server error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * 4. UPDATE COURSE RECORDBASE
     * URL: PUT /api/admin/course/{id}
     */
    public function update(Request $request, $id)
    {
        $course = Course::find($id);
        if (!$course) {
            return response()->json(['message' => 'Course not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'course_name' => 'required|string|max:255',
            'course_code' => 'required|string|unique:courses,course_code,' . $id,
            'short_name'  => 'required|string|max:50',
            'credit_hrs'  => 'required|string',
            'program_id'  => 'required|exists:programs,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $course->update($request->all());
            return response()->json([
                'message' => 'Course updated successfully',
                'data' => $course->load('program')
            ], 200);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Server Error: ' . $e->getMessage()], 500);
        }
    }

    /**
     * 5. DELETE COURSE RECORD
     * URL: DELETE /api/admin/course/{id}
     */
    public function destroy($id)
    {
        $course = Course::find($id);
        if (!$course) {
            return response()->json(['message' => 'Course already deleted or not found '], 404);
        }

        try {
            $course->delete();
            return response()->json(['message' => 'Course deleted successfully'], 200);
        } catch (\Exception $e) {
            // FIXED: Translated response error status message directly to clear English text format rules
            return response()->json(['message' => 'The course record could not be deleted due to foreign relational dependencies: ' . $e->getMessage()], 500);
        }
    }
}