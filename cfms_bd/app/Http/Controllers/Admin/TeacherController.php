<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Teacher;
use App\Models\User;
use App\Models\Department;
use App\Imports\TeacherImport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Facades\Excel;

class TeacherController extends Controller
{
    /**
     * Display a listing of teachers with cascaded relations.
     */
    public function index(Request $request)
    {
        $query = Teacher::with(['user', 'department']);

        // Screen department filter pipeline matching strictly 'dept_name'
        if ($request->has('department') && !empty($request->department)) {
            $deptFilter = $request->department;
            $query->whereHas('department', function($q) use ($deptFilter) {
                $q->where('dept_name', $deptFilter);
            });
        }

        $teachers = $query->latest()->get();

        return response()->json([
            'success' => true,
            'data' => $teachers
        ], 200);
    }

    /**
     * Update the specific teacher records within pipeline transactions.
     */
    public function update(Request $request, $id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher record not found.'], 404);
        }

        $validator = Validator::make($request->all(), [
            'teacher_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $teacher->user_id,
            'password' => 'nullable|min:6',
            'department_name' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failure on backend pipelines.',
                'errors' => $validator->errors()
            ], 422);
        }

        $department = Department::where('dept_name', $request->department_name)->first();

        if (!$department) {
            return response()->json([
                'message' => 'Validation failure on backend pipelines.',
                'errors' => ['department_name' => ['Targeted department does not exist in databases.']]
            ], 422);
        }

        DB::beginTransaction();
        try {
            // Update profile
            $teacher->update([
                'teacher_name' => $request->teacher_name,
                'dept_id' => $department->id,
            ]);

            // Sync account properties
            $userData = ['email' => $request->email];
            if ($request->filled('password')) {
                $userData['password'] = Hash::make($request->password);
            }
            
            User::where('id', $teacher->user_id)->update($userData);

            DB::commit();
            return response()->json(['message' => 'Teacher details updated successfully.'], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to save data record.'], 500);
        }
    }

    /**
     * Remove the teacher profile and cascade delete user credentials safely.
     */
    public function destroy($id)
    {
        $teacher = Teacher::find($id);
        if (!$teacher) {
            return response()->json(['message' => 'Teacher record not found.'], 404);
        }

        try {
            // Cascade delete user profile. Migration triggers teacher removal automatically
            User::destroy($teacher->user_id);

            return response()->json(['message' => 'Teacher record dropped successfully.'], 200);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Could not execute deletion pipeline.'], 500);
        }
    }

    /**
     * Upload and parse spreadsheet datasets bulk matrix.
     */
    public function import(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|mimes:xlsx,xls,csv|max:10240',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Data validation errors occurred during import.',
                'errors' => $validator->errors()
            ], 422);
        }

        DB::beginTransaction();
        try {
            Excel::import(new TeacherImport, $request->file('file'));
            DB::commit();

            return response()->json(['message' => 'Excel spreadsheet datasets imported successfully.'], 200);
        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Data validation errors occurred during import.',
                'errors' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            
            // Shows dynamic descriptive validation or SQL mismatches straight to Flutter
            return response()->json([
                'message' => 'Import Error: ' . $e->getMessage(),
                'errors' => ['file' => [$e->getMessage()]]
            ], 500);
        }
    }
}