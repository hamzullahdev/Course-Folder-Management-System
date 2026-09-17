<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Teacher\Result;
use App\Models\Teacher\Question;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ResultController extends Controller
{
    // 1. Get Enrolled Students (Ultra-Safe Smart Fetch for different Database Schemas)
    public function getStudents($allocationId)
    {
        $allocation = DB::table('course_allocations')->where('id', $allocationId)->first();
        if (!$allocation) {
            return response()->json(['success' => false, 'message' => 'Allocation not found', 'data' => []]);
        }

        // Get table columns dynamically to prevent SQL errors
        $columns = Schema::getColumnListing('enrollments');
        
        $query = Student::select('students.id', 'students.reg_no', 'students.std_name')
            ->join('enrollments', 'students.id', '=', 'enrollments.student_id')
            ->distinct();

        $filtered = false;

        // Try 1: Exact match by course_allocation_id
        if (in_array('course_allocation_id', $columns)) {
            $query->where('enrollments.course_allocation_id', $allocationId);
            $filtered = true;
        } 
        // Try 2: Match by course_offered_id
        elseif (in_array('course_offered_id', $columns) || in_array('courseOffered_id', $columns)) {
            $courseOfferedId = $allocation->course_offered_id ?? $allocation->courseOffered_id ?? null;

            if ($courseOfferedId) {
                $colName = in_array('course_offered_id', $columns) ? 'course_offered_id' : 'courseOffered_id';
                $query->where("enrollments.{$colName}", $courseOfferedId);
                
                // Also match section if available to be precise
                if (in_array('section', $columns) && isset($allocation->section)) {
                    $query->where('enrollments.section', $allocation->section);
                }
                $filtered = true;
            }
        }

        $students = $filtered ? $query->get() : collect();

        // SUPER FALLBACK: If strict matching is empty, ignore section and just get students for the course
        if ($students->isEmpty()) {
            $courseOfferedId = $allocation->course_offered_id ?? $allocation->courseOffered_id ?? null;
            $colName = in_array('course_offered_id', $columns) ? 'course_offered_id' : (in_array('courseOffered_id', $columns) ? 'courseOffered_id' : null);

            if ($courseOfferedId && $colName) {
                 $students = Student::select('students.id', 'students.reg_no', 'students.std_name')
                    ->join('enrollments', 'students.id', '=', 'enrollments.student_id')
                    ->where("enrollments.{$colName}", $courseOfferedId)
                    ->distinct()
                    ->get();
            }
        }

        return response()->json(['success' => true, 'data' => $students]);
    }

    // 2. Get all saved results for a specific Question
    public function index($questionId)
    {
        $results = Result::with('student')->where('question_id', $questionId)->get();
        return response()->json(['success' => true, 'data' => $results]);
    }

    // 3. Store Bulk Results from Entry Screen
    public function storeBulk(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'question_id' => 'required|exists:questions,id',
            'marks'       => 'required|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        // Use updateOrCreate to avoid duplicates if marks are updated multiple times
        foreach ($request->marks as $student_id => $obtained_marks) {
            if ($obtained_marks !== null && $obtained_marks !== '') {
                Result::updateOrCreate(
                    ['student_id' => $student_id, 'question_id' => $request->question_id],
                    ['obtained_marks' => $obtained_marks]
                );
            }
        }

        return response()->json(['success' => true, 'message' => 'Results saved successfully.']);
    }

    // 4. Update Single Result (From Action Edit)
    public function update(Request $request, $id)
    {
        $result = Result::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'obtained_marks' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $result->update(['obtained_marks' => $request->obtained_marks]);

        return response()->json(['success' => true, 'message' => 'Result updated successfully.']);
    }

    // 5. Delete Single Result
    public function destroy($id)
    {
        $result = Result::findOrFail($id);
        $result->delete();

        return response()->json(['success' => true, 'message' => 'Result deleted successfully.']);
    }
}