<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\File;
use App\Models\Teacher\FileSubmission;
use Illuminate\Http\Request;
use Exception;

class ChecklistController extends Controller
{
    /**
     * Get the checklist status for a specific course allocation.
     */
    public function getChecklist($allocationId)
    {
        try {
            // Fetch all system-required files
            $allFiles = File::all();

            // Fetch submissions made by the teacher for this specific allocation
            $submissions = FileSubmission::where('course_allocation_id', $allocationId)
                                         ->get()
                                         ->keyBy('file_id');

            // Map the files to determine status
            $checklist = $allFiles->map(function ($file) use ($submissions) {
                $submission = $submissions->get($file->file_id);

                return [
                    'file_id'   => $file->file_id,
                    'file_name' => $file->file_name,
                    'status'    => $submission ? 'Complete' : 'Incomplete',
                    'file_path' => $submission ? $submission->file_path : null,
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'Checklist retrieved successfully.',
                'data'    => $checklist
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve checklist.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}