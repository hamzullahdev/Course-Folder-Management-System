<?php

namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\Batch;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Validator;

class BatchController extends Controller
{
    /**
     * 1. Get all batches (with their program details)
     */
    public function index()
    {
        // Eager load the program to avoid N+1 query performance issues
        $batches = Batch::with('program')->get();
        
        return response()->json([
            'success' => true,
            'data' => $batches
        ], 200);
    }

    /**
     * 2. Store a newly created batch
     */
    public function store(Request $request)
    {
        // Validation logic handling the composite unique key
        $validator = Validator::make($request->all(), [
            'batch_name' => 'required|string|max:255',
            'program_id' => [
                'required',
                'exists:programs,id',
                Rule::unique('batches')->where(function ($query) use ($request) {
                    return $query->where('batch_name', $request->batch_name)
                                 ->where('program_id', $request->program_id);
                })
            ],
        ], [
            // Custom English error message for duplicate batch in the same program
            'program_id.unique' => 'This batch name already exists for the selected program.'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $batch = Batch::create([
                'batch_name' => $request->batch_name,
                'program_id' => $request->program_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Batch created successfully.',
                'data' => $batch
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create batch.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * 3. Show a specific batch
     */
    public function show($id)
    {
        $batch = Batch::with('program')->find($id);

        if (!$batch) {
            return response()->json([
                'success' => false,
                'message' => 'Batch not found.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $batch
        ], 200);
    }

    /**
     * 4. Update the specified batch
     */
    public function update(Request $request, $id)
    {
        $batch = Batch::find($id);

        if (!$batch) {
            return response()->json([
                'success' => false,
                'message' => 'Batch not found.'
            ], 404);
        }

        // Validation logic for update, ignoring the current batch's ID in the unique check
        $validator = Validator::make($request->all(), [
            'batch_name' => 'sometimes|required|string|max:255',
            'program_id' => [
                'sometimes',
                'required',
                'exists:programs,id',
                Rule::unique('batches')->where(function ($query) use ($request, $batch) {
                    return $query->where('batch_name', $request->batch_name ?? $batch->batch_name)
                                 ->where('program_id', $request->program_id ?? $batch->program_id);
                })->ignore($batch->id)
            ],
        ], [
            'program_id.unique' => 'This batch name already exists for the selected program.'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $batch->update($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Batch updated successfully.',
                'data' => $batch
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update batch.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * 5. Remove the specified batch
     */
    public function destroy($id)
    {
        $batch = Batch::find($id);

        if (!$batch) {
            return response()->json([
                'success' => false,
                'message' => 'Batch not found.'
            ], 404);
        }

        try {
            $batch->delete();

            return response()->json([
                'success' => true,
                'message' => 'Batch deleted successfully.'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete batch.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}