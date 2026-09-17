<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Folder;
use App\Models\File;
use App\Models\Teacher\FileSubmission;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB; // ✨ LAZMI HAI
use Exception;

class FileSubmissionController extends Controller
{
    public function getFolders()
    {
        try {
            $folders = Folder::all();
            return response()->json(['success' => true, 'data' => $folders], 200);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to load folders.'], 500);
        }
    }

    public function getFilesByFolder($folderId)
    {
        try {
            $files = File::where('folder_id', $folderId)->get();
            return response()->json(['success' => true, 'data' => $files], 200);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to load files.'], 500);
        }
    }

    public function getSubmissions($allocationId)
    {
        try {
            // ✨ YAHAN DATA JOIN KAR RAHA HOON TAAKE GRID MEIN DIKH SAKE
            $submissions = DB::table('file_submissions')
                ->join('files', 'file_submissions.file_id', '=', 'files.file_id')
                ->where('file_submissions.course_allocation_id', $allocationId)
                ->select('file_submissions.*', 'files.file_name')
                ->get();
                
            return response()->json(['success' => true, 'data' => $submissions], 200);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to fetch submissions.'], 500);
        }
    }

    public function uploadFile(Request $request)
    {
        $request->validate([
            'course_allocation_id' => 'required|integer',
            'file_id' => 'required|integer',
            'document' => 'required|file|mimes:pdf,doc,docx,xls,xlsx|max:10240',
        ]);

        try {
            $allocationId = $request->course_allocation_id;
            $fileId = $request->file_id;

            $existingSubmission = FileSubmission::where('course_allocation_id', $allocationId)
                ->where('file_id', $fileId)
                ->first();

            $file = $request->file('document');
            $fileName = time() . '_' . $file->getClientOriginalName(); 
            $filePath = $file->storeAs('submissions', $fileName, 'public');

            if ($existingSubmission) {
                if (Storage::disk('public')->exists($existingSubmission->file_path)) {
                    Storage::disk('public')->delete($existingSubmission->file_path);
                }
                $existingSubmission->update([
                    'file_path' => $filePath,
                    'uploaded_at' => now(),
                ]);
                $message = 'File updated successfully.';
            } else {
                FileSubmission::create([
                    'course_allocation_id' => $allocationId,
                    'file_id' => $fileId,
                    'file_path' => $filePath,
                    'uploaded_at' => now(),
                ]);
                $message = 'File uploaded successfully.';
            }

            return response()->json(['success' => true, 'message' => $message], 200);

        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to upload file.', 'error' => $e->getMessage()], 500);
        }
    }
}