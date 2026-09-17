<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Folder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class SubFolderController extends Controller
{
    /**
     * Retrieve folders that can act as parents (no_of_files == 0).
     * This includes both root folders and empty sub-folders.
     */
    public function parentFolders()
    {
        try {
            $parents = Folder::where('no_of_files', 0)->get();
            return response()->json([
                'success' => true,
                'data'    => $parents
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve parent folders.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Retrieve all sub-folders (folders that have a parent_id).
     */
    public function index()
    {
        try {
            $subFolders = Folder::with('parent')->whereNotNull('parent_id')->get();
            return response()->json([
                'success' => true,
                'data'    => $subFolders
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve sub-folders.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created sub-folder.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'folder_name' => 'required|string|unique:folders,folder_name|max:255',
            'no_of_files' => 'nullable|integer|min:0',
            'parent_id'   => 'required|exists:folders,folder_id' // Must have a parent
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $subFolder = Folder::create([
                'folder_name' => $request->folder_name,
                'no_of_files' => $request->no_of_files ?? 0,
                'parent_id'   => $request->parent_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Sub-folder created successfully.',
                'data'    => $subFolder->load('parent')
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create sub-folder.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update the specified sub-folder.
     */
    public function update(Request $request, $id)
    {
        $subFolder = Folder::whereNotNull('parent_id')->find($id);

        if (!$subFolder) {
            return response()->json([
                'success' => false,
                'message' => 'Sub-folder not found.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'folder_name' => 'required|string|max:255|unique:folders,folder_name,' . $id . ',folder_id',
            'no_of_files' => 'nullable|integer|min:0',
            'parent_id'   => 'required|exists:folders,folder_id'
        ]);

        if ($request->parent_id == $id) {
            return response()->json([
                'success' => false,
                'message' => 'A sub-folder cannot be its own parent.'
            ], 409);
        }

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $subFolder->update([
                'folder_name' => $request->folder_name,
                'no_of_files' => $request->no_of_files ?? $subFolder->no_of_files,
                'parent_id'   => $request->parent_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Sub-folder updated successfully.',
                'data'    => $subFolder->load('parent')
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Update execution failed.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified sub-folder.
     */
    public function destroy($id)
    {
        try {
            $subFolder = Folder::whereNotNull('parent_id')->find($id);

            if (!$subFolder) {
                return response()->json([
                    'success' => false,
                    'message' => 'Sub-folder not found.'
                ], 404);
            }

            $subFolder->delete();

            return response()->json([
                'success' => true,
                'message' => 'Sub-folder deleted cleanly.'
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete the sub-folder.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}