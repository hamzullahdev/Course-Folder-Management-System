<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Session;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SessionController extends Controller
{
    /**
     * 1. Display a listing of all sessions.
     */
    public function index()
    {
        try {
            $sessions = Session::orderBy('id', 'desc')->get();
            
            return response()->json([
                'success' => true,
                'data' => $sessions
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Database error occurred while fetching sessions: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 2. Store a newly created session in the database.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            's_name'     => 'required|string|max:255',
            'start_date' => 'required|date_format:d/m/Y',
            'end_date'   => 'required|date_format:d/m/Y|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors occurred.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $session = Session::create([
                's_name'     => $request->s_name,
                'start_date' => $request->start_date,
                'end_date'   => $request->end_date,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Session created successfully.',
                'data'    => $session
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create session: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 3. Display the specified session resource.
     */
    public function show($id)
    {
        $session = Session::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Requested session record not found.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $session
        ], 200);
    }

    /**
     * 4. Update the specified session inside the database.
     */
    public function update(Request $request, $id)
    {
        $session = Session::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session not found to perform modification.'
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            's_name'     => 'required|string|max:255',
            'start_date' => 'required|date_format:d/m/Y',
            'end_date'   => 'required|date_format:d/m/Y|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation errors occurred.',
                'errors'  => $validator->errors()
            ], 422);
        }

        try {
            $session->update([
                's_name'     => $request->s_name,
                'start_date' => $request->start_date,
                'end_date'   => $request->end_date,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Session updated successfully.',
                'data'    => $session
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to update session data: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 5. Remove the specified session from storage.
     */
    public function destroy($id)
    {
        $session = Session::find($id);

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'Session record already missing or deleted.'
            ], 404);
        }

        try {
            $session->delete();

            return response()->json([
                'success' => true,
                'message' => 'Session record removed successfully from database.'
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'System error occurred during record deletion: ' . $e->getMessage()
            ], 500);
        }
    }
}