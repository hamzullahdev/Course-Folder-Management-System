<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Teacher\Assessment;
use App\Models\CourseAllocation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AssessmentController extends Controller
{
    public function index($allocationId)
    {
        $assessments = Assessment::where('course_allocation_id', $allocationId)->get();
        return response()->json(['success' => true, 'data' => $assessments]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'course_allocation_id' => 'required|exists:course_allocations,id',
            'type' => 'required|string',
            'weightage' => 'required|integer|min:1|max:100',
        ]);

        if ($validator->fails()) return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);

        // 1. Duplicate check
        if (Assessment::where('course_allocation_id', $request->course_allocation_id)->where('type', $request->type)->exists()) {
            return response()->json(['success' => false, 'message' => 'This assessment type already exists for this course.'], 400);
        }

        // 2. Weightage limit check (100%)
        $currentTotal = Assessment::where('course_allocation_id', $request->course_allocation_id)->sum('weightage');
        if (($currentTotal + $request->weightage) > 100) {
            return response()->json(['success' => false, 'message' => 'Total weightage cannot exceed 100%. Current total: ' . $currentTotal . '%'], 400);
        }

        Assessment::create($request->all());
        return response()->json(['success' => true, 'message' => 'Assessment saved successfully.']);
    }

    public function destroy($id)
    {
        Assessment::destroy($id);
        return response()->json(['success' => true, 'message' => 'Assessment deleted.']);
    }

    public function update(Request $request, $id)
    {
    $assessment = Assessment::findOrFail($id);
    
    $request->validate([
        'weightage' => 'required|integer|min:1|max:100',
    ]);

    // Check if new weightage exceeds 100% total (excluding current assessment)
    $currentTotal = Assessment::where('course_allocation_id', $assessment->course_allocation_id)
                    ->where('id', '!=', $id)
                    ->sum('weightage');

    if (($currentTotal + $request->weightage) > 100) {
        return response()->json(['success' => false, 'message' => 'Total weightage cannot exceed 100%.'], 400);
    }

    $assessment->update(['weightage' => $request->weightage]);
    return response()->json(['success' => true, 'message' => 'Assessment updated successfully.']);
    }
}