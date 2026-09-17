<?php

namespace App\Imports;

use App\Models\Student;
use App\Models\Program;
use App\Models\Batch;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class StudentImport implements ToModel, WithHeadingRow, WithValidation
{
    public function prepareForValidation($data, $index)
    {
        return [
            'name'     => isset($data['name']) ? trim($data['name']) : (isset($data['Name']) ? trim($data['Name']) : null),
            'regno'    => isset($data['regno']) ? trim($data['regno']) : (isset($data['RegNo']) ? trim($data['RegNo']) : null),
            'program'  => isset($data['program']) ? trim($data['program']) : (isset($data['Program']) ? trim($data['Program']) : null),
            'batch'    => isset($data['batch']) ? trim($data['batch']) : (isset($data['Batch']) ? trim($data['Batch']) : null),
            // ✨ FIX: Naye columns add kiye
            'email'    => isset($data['email']) ? trim($data['email']) : (isset($data['Email']) ? trim($data['Email']) : null),
            'password' => isset($data['password']) ? trim($data['password']) : (isset($data['Password']) ? trim($data['Password']) : null),
        ];
    }

    public function model(array $row)
    {
        $name = isset($row['name']) ? trim($row['name']) : (isset($row['Name']) ? trim($row['Name']) : null);
        $regNo = isset($row['regno']) ? trim($row['regno']) : (isset($row['RegNo']) ? trim($row['RegNo']) : null);
        $programName = isset($row['program']) ? trim($row['program']) : (isset($row['Program']) ? trim($row['Program']) : null);
        $batchName = isset($row['batch']) ? trim($row['batch']) : (isset($row['Batch']) ? trim($row['Batch']) : null);
        $email = isset($row['email']) ? trim($row['email']) : (isset($row['Email']) ? trim($row['Email']) : null);
        $password = isset($row['password']) ? trim($row['password']) : (isset($row['Password']) ? trim($row['Password']) : null);

        $programId = Program::where('program_name', $programName)->value('id');
        $batchId = Batch::where('batch_name', $batchName)->value('id');

        // ✨ FIX: Pehle User account create karein
        $user = User::create([
            'email'    => $email,
            'password' => Hash::make($password),
            'role'     => 'student',
        ]);

        // ✨ FIX: Phir Student create karein aur user_id de dein
        return new Student([
            'std_name'   => $name,    
            'reg_no'     => $regNo,   
            'program_id' => $programId,
            'batch_id'   => $batchId,
            'user_id'    => $user->id, 
        ]);
    }

    public function rules(): array
    {
        return [
            'name'     => 'required|string|max:255',
            'regno'    => 'required|string|max:100|unique:students,reg_no',
            'program'  => 'required|string|exists:programs,program_name',
            'batch'    => 'required|string|exists:batches,batch_name',
            // ✨ FIX: Users table mein email check karni hai
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
        ];
    }

    public function customValidationMessages()
    {
        return [
            'name.required'    => 'Student name is required.',
            'regno.unique'     => 'The registration number ":input" already exists.',
            'email.unique'     => 'The email ":input" is already registered as a user.',
            'password.min'     => 'Password must be at least 6 characters.',
        ];
    }
}