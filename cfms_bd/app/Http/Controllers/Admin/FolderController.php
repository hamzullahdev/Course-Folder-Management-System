<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Folder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class FolderController extends Controller
{
    /**
     * Retrieve all folders along with their subfolders.
     */
    public function index()
    {
        try {
            // Fetch all folders with their immediate subfolders
            $folders = Folder::with('subfolders')->get();

            return response()->json([
                'success' => true,
                'data'    => $folders
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve folder structures.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created folder in the database.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'folder_name' => 'required|string|unique:folders,folder_name|max:255',
            'no_of_files' => 'nullable|integer|min:0',
            'parent_id'   => 'nullable|exists:folders,folder_id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Data validation failed.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $folder = Folder::create([
                'folder_name' => $request->folder_name,
                'no_of_files' => $request->no_of_files ?? 0,
                'parent_id'   => $request->parent_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Folder created successfully.',
                'data'    => $folder
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create the folder due to an internal error.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified folder details.
     */
    public function show($id)
    {
        $folder = Folder::with(['subfolders', 'parent'])->find($id);

        if (!$folder) {
            return response()->json([
                'success' => false,
                'message' => 'Requested folder not found.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $folder
        ], 200);
    }

    /**
     * Update the specified folder in storage.
     */
    public function update(Request $request, $id)
    {
        $folder = Folder::find($id);

        if (!$folder) {
            return response()->json([
                'success' => false,
                'message' => 'Target folder does not exist.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            // Unique rule ignores the current folder ID to allow updating other fields safely
            'folder_name' => 'required|string|max:255|unique:folders,folder_name,' . $id . ',folder_id',
            'no_of_files' => 'nullable|integer|min:0',
            'parent_id'   => 'nullable|exists:folders,folder_id'
        ]);

        // Structural Integrity Check: A folder cannot be assigned as its own parent
        if ($request->parent_id == $id) {
            return response()->json([
                'success' => false,
                'message' => 'Structural conflict: A folder cannot be its own parent.'
            ], 409);
        }

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error during update.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $folder->update([
                'folder_name' => $request->folder_name,
                'no_of_files' => $request->no_of_files ?? $folder->no_of_files,
                'parent_id'   => $request->parent_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Folder attributes updated correctly.',
                'data'    => $folder->load(['subfolders', 'parent'])
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Database execution failed while updating.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified folder from storage.
     */
    public function destroy($id)
    {
        try {
            $folder = Folder::find($id);

            if (!$folder) {
                return response()->json([
                    'success' => false,
                    'message' => 'Folder instance not found.'
                ], 404);
            }

            // Migration handles cascading deletes automatically, 
            // so deleting this will cleanly wipe all nested subfolders attached to it.
            $folder->delete();

            return response()->json([
                'success' => true,
                'message' => 'Folder and its entire nested hierarchy deleted successfully.'
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete the folder context.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}