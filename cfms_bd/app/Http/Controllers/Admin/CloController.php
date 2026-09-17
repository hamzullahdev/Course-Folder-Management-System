<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Clo;
use App\Models\CourseCloSession; // Added this model for pivot record creation
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Exception;

class CloController extends Controller
{
/**
     * Fetch all CLO records with explicit casting to ensure Flutter string evaluation matching.
     */
    public function index()
    {
        try {
            // ✨ FIX: leftJoin laga kar course_clo_session table se session_id fetch kiya hai
            $clos = Clo::leftJoin('course_clo_session', 'clos.id', '=', 'course_clo_session.clo_id')
                ->select('clos.*', 'course_clo_session.session_id')
                ->with('course')
                ->get();
            
            $transformedClos = $clos->map(function ($clo) {
                return [
                    'id'               => (string)$clo->id,
                    'clos_code'        => $clo->clos_code,
                    'clos_description' => $clo->clos_description,
                    'course_id'        => (string)$clo->course_id,
                    'session_id'       => $clo->session_id ? (string)$clo->session_id : null, // ✨ Session ID added here
                    'created_at'       => $clo->created_at,
                    'updated_at'       => $clo->updated_at,
                    'course'           => $clo->course
                ];
            });

            return response()->json([
                'success' => true,
                'message' => 'CLOs retrieved successfully.',
                'data'    => $transformedClos
            ], 200);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to retrieve data due to operational runtime constraints.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a newly created CLO mapping resource with unique compound verification.
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'clos_code'        => 'required|string|max:255',
                'clos_description' => 'required|string',
                'course_id'        => 'required|exists:courses,id',
                'session_id'       => 'required|exists:sessions,id' // Validating session
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation parameters missing or invalid.',
                    'errors'  => $validator->errors()
                ], 422);
            }

            // Explicit Matrix unique boundary validation
            $isDuplicate = Clo::where('clos_code', trim($request->clos_code))
                ->where('course_id', $request->course_id)
                ->exists();

            if ($isDuplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'This CLO code configuration already exists for the selected course context.'
                ], 409);
            }

            // Creating the CLO
            $clo = Clo::create([
                'clos_code'        => trim($request->clos_code),
                'clos_description' => trim($request->clos_description),
                'course_id'        => $request->course_id
            ]);

            // Storing relation in CourseCloSession pivot table
            CourseCloSession::create([
                'course_id'  => $request->course_id,
                'clo_id'     => $clo->id,
                'session_id' => $request->session_id
            ]);

            return response()->json([
                'success' => true,
                'message' => 'CLO configured successfully.',
                'data'    => $clo
            ], 201);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Process failed. System rejected entry manipulation.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified CLO record detail.
     */
    public function show($id)
    {
        try {
            $clo = Clo::with('course')->find($id);

            if (!$clo) {
                return response()->json([
                    'success' => false,
                    'message' => 'No records match selection criteria.'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Data record verified successfully.',
                'data'    => $clo
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Internal process failure encountered.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update specified CLO parameters dynamically.
     */
    public function update(Request $request, $id)
    {
        try {
            $clo = Clo::find($id);

            if (!$clo) {
                return response()->json([
                    'success' => false,
                    'message' => 'Requested record asset not found.'
                ], 404);
            }

            $validator = Validator::make($request->all(), [
                'clos_code'        => 'sometimes|required|string|max:255',
                'clos_description' => 'sometimes|required|string',
                'course_id'        => 'sometimes|required|exists:courses,id'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to save modifications due to payload discrepancies.',
                    'errors'  => $validator->errors()
                ], 422);
            }

            $targetCourseId = $request->has('course_id') ? $request->course_id : $clo->course_id;
            $targetCloCode  = $request->has('clos_code') ? trim($request->clos_code) : $clo->clos_code;

            $isDuplicate = Clo::where('clos_code', $targetCloCode)
                ->where('course_id', $targetCourseId)
                ->where('id', '!=', $id)
                ->exists();

            if ($isDuplicate) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot modify. An entry with identical parameter sets already exists.'
                ], 409);
            }

            $clo->update([
                'clos_code'        => $request->has('clos_code') ? trim($request->clos_code) : $clo->clos_code,
                'clos_description' => $request->has('clos_description') ? trim($request->clos_description) : $clo->clos_description,
                'course_id'        => $targetCourseId
            ]);

            return response()->json([
                'success' => true,
                'message' => 'CLO structural properties updated successfully.',
                'data'    => $clo
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to write mutations to database engine.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Purge single CLO asset. Relational integrity handled by cascade on database side.
     */
    public function destroy($id)
    {
        try {
            $clo = Clo::find($id);

            if (!$clo) {
                return response()->json([
                    'success' => false,
                    'message' => 'Target entity reference missing inside runtime scope.'
                ], 404);
            }

            $clo->delete();

            return response()->json([
                'success' => true,
                'message' => 'CLO operational profile purged successfully.'
            ], 200);

        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete record due to operational relational constraints.',
                'error'   => $e->getMessage()
            ], 500);
        }
    }
}