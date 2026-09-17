<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Clo;
use App\Models\PLOs;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Exception;

class ClosPlosMappingController extends Controller
{
    /**
     * Get CLOs, Program-specific PLOs, and existing mappings for the grid.
     */
    public function getMappingData($courseId)
    {
        try {
            // 1. Fetch CLOs for the selected course
            $clos = Clo::where('course_id', $courseId)->get();
            
            // 2. Find the course from database to extract its program_id
            $course = DB::table('courses')->where('id', $courseId)->first();

            // 3. Smart Filtering: Fetch PLOs belonging ONLY to this course's program
            if ($course && isset($course->program_id)) {
                $plos = PLOs::where('program_id', $course->program_id)->get();
            } else {
                // Fallback: If program_id column is missing or null, fetch all as safety measure
                $plos = PLOs::all();
            }

            // 4. Fetch existing pivot mappings for these specific CLOs
            $cloIds = $clos->pluck('id');
            $mappings = DB::table('clo_plo')->whereIn('clo_id', $cloIds)->get();

            return response()->json([
                'success' => true,
                'message' => 'Program specific mapping data retrieved successfully.',
                'data' => [
                    'clos' => $clos,
                    'plos' => $plos,
                    'mappings' => $mappings
                ]
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve filtered mapping data.',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Save or Sync the CLO-PLO matrix mappings.
     */
    public function saveMapping(Request $request)
    {
        try {
            $request->validate([
                'course_id' => 'required',
                'mappings'  => 'array'
            ]);

            $cloIds = Clo::where('course_id', $request->course_id)->pluck('id');

            DB::beginTransaction();

            // Remove previous constraints for this course scope
            DB::table('clo_plo')->whereIn('clo_id', $cloIds)->delete();

            // Save fresh operational matrix states
            if (!empty($request->mappings)) {
                DB::table('clo_plo')->insert($request->mappings);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'CLO-PLO configurations synchronized successfully.'
            ], 200);

        } catch (Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Matrix synchronization failed due to processing constraints.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}