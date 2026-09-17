<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\File as FileModel; // Aliased to prevent conflict with Laravel's File facade
use App\Models\Folder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class FileController extends Controller
{
    /**
     * Fetch folders that have at least 1 file capacity/limit (no_of_files > 0)
     */
    public function validFolders()
    {
        try {
            $folders = Folder::where('no_of_files', '>', 0)->get();
            return response()->json([
                'success' => true,
                'data'    => $folders
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve eligible folders.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Retrieve all files with their folder relation.
     */
    public function index()
    {
        try {
            $files = FileModel::with('folder')->get();
            return response()->json([
                'success' => true,
                'data'    => $files
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve files.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created file.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file_name' => 'required|string|max:255|unique:files,file_name',
            'folder_id' => 'required|exists:folders,folder_id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $file = FileModel::create([
                'file_name' => $request->file_name,
                'folder_id' => $request->folder_id,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'File created successfully.',
                'data'    => $file->load('folder')
            ], 201);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to store the file.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update the specified file.
     */
    public function update(Request $request, $id)
    {
        $file = FileModel::find($id);

        if (!$file) {
            return response()->json([
                'success' => false,
                'message' => 'File not found in the database.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'file_name' => 'required|string|max:255|unique:files,file_name,' . $id . ',file_id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $file->update([
                'file_name' => $request->file_name,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'File details updated successfully.',
                'data'    => $file->load('folder')
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update the file.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified file.
     */
    public function destroy($id)
    {
        try {
            $file = FileModel::find($id);

            if (!$file) {
                return response()->json([
                    'success' => false,
                    'message' => 'Target file does not exist.'
                ], 404);
            }

            $file->delete();

            return response()->json([
                'success' => true,
                'message' => 'File deleted successfully.'
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete the file.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}