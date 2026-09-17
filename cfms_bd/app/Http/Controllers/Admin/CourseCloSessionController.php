<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CourseCloSession;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class CourseCloSessionController extends Controller
{
    // 1. GET ALL RECORDS
    public function index()
    {
        try {
            // Fetch records with related Course, CLO, and Session names
            $data = CourseCloSession::with(['course', 'clo', 'session'])->get();
            
            return response()->json([
                'success' => true,
                'data' => $data
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve records.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    // 2. STORE NEW RECORD
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'course_id' => 'required|exists:courses,id',
            'clo_id' => 'required|exists:clos,id',
            'session_id' => 'required|exists:sessions,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        // Duplicate Check: Same Course, CLO, and Session combination
        $exists = CourseCloSession::where('course_id', $request->course_id)
            ->where('clo_id', $request->clo_id)
            ->where('session_id', $request->session_id)
            ->exists();

        if ($exists) {
            return response()->json(['success' => false, 'message' => 'This mapping already exists.'], 400);
        }

        try {
            $record = CourseCloSession::create($request->all());
            return response()->json([
                'success' => true,
                'message' => 'Mapping created successfully.',
                'data' => $record
            ], 201);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to create mapping.', 'error' => $e->getMessage()], 500);
        }
    }

    // 3. SHOW SINGLE RECORD (FOR EDIT FORM)
    public function show($id)
    {
        try {
            $record = CourseCloSession::with(['course', 'clo', 'session'])->find($id);
            
            if (!$record) {
                return response()->json(['success' => false, 'message' => 'Record not found.'], 404);
            }

            return response()->json(['success' => true, 'data' => $record], 200);

        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to retrieve record.', 'error' => $e->getMessage()], 500);
        }
    }

    // 4. UPDATE RECORD
    public function update(Request $request, $id)
    {
        $record = CourseCloSession::find($id);

        if (!$record) {
            return response()->json(['success' => false, 'message' => 'Record not found.'], 404);
        }

        $validator = Validator::make($request->all(), [
            'course_id' => 'required|exists:courses,id',
            'clo_id' => 'required|exists:clos,id',
            'session_id' => 'required|exists:sessions,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        // Duplicate Check (Excluding current updating ID)
        $exists = CourseCloSession::where('course_id', $request->course_id)
            ->where('clo_id', $request->clo_id)
            ->where('session_id', $request->session_id)
            ->where('id', '!=', $id)
            ->exists();

        if ($exists) {
            return response()->json(['success' => false, 'message' => 'Another mapping with these details already exists.'], 400);
        }

        try {
            $record->update($request->all());
            return response()->json([
                'success' => true,
                'message' => 'Mapping updated successfully.',
                'data' => $record
            ], 200);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to update mapping.', 'error' => $e->getMessage()], 500);
        }
    }

    // 5. DELETE RECORD
    public function destroy($id)
    {
        try {
            $record = CourseCloSession::find($id);
            
            if (!$record) {
                return response()->json(['success' => false, 'message' => 'Record not found.'], 404);
            }

            $record->delete();
            return response()->json(['success' => true, 'message' => 'Mapping deleted successfully.'], 200);

        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to delete mapping.', 'error' => $e->getMessage()], 500);
        }
    }
}