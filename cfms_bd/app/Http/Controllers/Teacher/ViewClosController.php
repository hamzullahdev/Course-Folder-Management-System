<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Clo;
use Illuminate\Http\Request;
use Exception;

class ViewClosController extends Controller
{
    /**
     * Fetch CLOs associated with a specific course.
     */
    public function getClosByCourse($courseId)
    {
        try {
            // Find all CLOs where course_id matches the selected course
            $clos = Clo::where('course_id', $courseId)->get();

            return response()->json([
                'success' => true,
                'message' => 'CLOs retrieved successfully.',
                'data'    => $clos
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch CLOs due to server error.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}