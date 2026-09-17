<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CourseAllocation;
use App\Imports\CourseAllocationImport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Facades\Excel;
use Exception;

class CourseAllocationController extends Controller
{
    /**
     * Retrieve all course allocations with relationships.
     */
    public function index()
    {
        try {
            $allocations = CourseAllocation::with([
                'teacher',
                'courseOffered.course.program.department',
                'session',
                'batch'
            ])->get();

            return response()->json([
                'success' => true,
                'data'    => $allocations
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch course allocations.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Import allocations via Excel/CSV.
     */
    public function import(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|mimes:xlsx,xls,csv|max:10240',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid file format uploaded.',
                'errors'  => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            Excel::import(new CourseAllocationImport, $request->file('file'));
            
            DB::commit();
            return response()->json([
                'success' => true,
                'message' => 'Course allocations imported successfully.'
            ], 200);
        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'An error occurred during the import process.',
                'error'   => $e->getMessage()
            ], 400);
        }
    }

    /**
     * Update an existing allocation.
     */
    public function update(Request $request, $id)
    {
        $allocation = CourseAllocation::find($id);

        if (!$allocation) {
            return response()->json([
                'success' => false,
                'message' => 'Allocation record not found.'
            ], 404);
        }

        try {
            $allocation->update($request->only(['status', 'reason', 'section']));

            return response()->json([
                'success' => true,
                'message' => 'Course allocation updated successfully.',
                'data'    => $allocation->load(['teacher', 'courseOffered.course', 'session', 'batch'])
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update course allocation.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete an allocation.
     */
    public function destroy($id)
    {
        try {
            $allocation = CourseAllocation::find($id);

            if (!$allocation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Record not found.'
                ], 404);
            }

            $allocation->delete();

            return response()->json([
                'success' => true,
                'message' => 'Course allocation deleted successfully.'
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete the record.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}