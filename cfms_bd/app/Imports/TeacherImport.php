<?php

namespace App\Imports;

use App\Models\User;
use App\Models\Teacher;
use App\Models\Department;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Validation\ValidationException;

class TeacherImport implements ToCollection, WithHeadingRow
{
    public function collection(Collection $rows)
    {
        $rowsArray = $rows->toArray();
        
        // 1. Bulk check for standard header constraints
        $validator = Validator::make($rowsArray, [
            '*.name' => 'required|string|max:255',
            '*.email' => 'required|email|unique:users,email',
            '*.password' => 'required|min:6',
            '*.department' => 'required|string',
        ], [
            '*.email.unique' => 'Row :attribute: This email identity is already registered inside system.',
            '*.name.required' => 'Teacher Name column value cannot be left blank.',
            '*.department.required' => 'Department designation field is missing.',
        ]);

        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        // 2. Sequential insertion matching database relations
        foreach ($rows as $index => $row) {
            $deptName = trim($row['department']);
            
            // ✨ STABLE FIX: Pure database pipeline query matching ONLY 'dept_name' column
            $department = Department::where('dept_name', $deptName)->first();

            if (!$department) {
                $error = ValidationException::withMessages([
                    'file' => ["Row " . ($index + 2) . ": Department alignment error! '{$deptName}' does not exist in backend schema context."]
                ]);
                throw $error;
            }

            // Create Primary Identity
            $user = User::create([
                'email' => trim($row['email']),
                'password' => Hash::make($row['password']),
                'role' => 'teacher', // Identity defaults to teacher profile
            ]);

            // Create Sub-profile Reference Link
            Teacher::create([
                'user_id' => $user->id,
                'dept_id' => $department->id,
                'teacher_name' => trim($row['name']),
            ]);
        }
    }
}