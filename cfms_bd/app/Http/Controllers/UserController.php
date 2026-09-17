<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    public function login(Request $request)
    {
        // 1. Validation
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // 2. Find User
        $user = User::where('email', $request->email)->first();

        // 3. Verify User and Password
        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        // 4. Generate Token
        $token = $user->createToken('auth_token')->plainTextToken;

        // 5. Return Response with Role
        return response()->json([
            'message' => 'Login successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'role' => $user->role, 
        ]);
    }

    /**
     * 🔽 User Logout Method (Sanctum Tokens Revoke karne ke liye)
     */
    public function logout(Request $request)
    {
        // Current request ka authorization token delete karne ke liye
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.'
        ], 200);
    }
}