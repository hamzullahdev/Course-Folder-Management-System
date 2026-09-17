<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class ChangePasswordController extends Controller
{
    /**
     * Update the authenticated teacher's password.
     */
    public function updatePassword(Request $request)
    {
        // 1. Validation Rules
        $validator = Validator::make($request->all(), [
            'current_password' => 'required',
            'new_password'     => 'required|min:8',
            'confirm_password' => 'required|same:new_password'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false, 
                'message' => $validator->errors()->first()
            ], 422);
        }

        // 2. Get the currently authenticated user
        $user = $request->user();

        // 3. Verify Current Password
        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false, 
                'message' => 'The current password you entered is incorrect.'
            ], 400);
        }

        // 4. Update and Hash New Password
        $user->password = Hash::make($request->new_password);
        $user->save();

        return response()->json([
            'success' => true, 
            'message' => 'Password has been updated successfully.'
        ], 200);
    }
}