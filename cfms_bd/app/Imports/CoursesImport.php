<?php

namespace App\Imports;

use App\Models\Course;
use App\Models\Program;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class CoursesImport implements ToModel, WithHeadingRow, WithValidation
{
    /**
     * @param array $row
     *
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public function model(array $row)
    {
        // FIXED: Changed column selector from 'name' to 'program_name'
        $program = Program::where('program_name', trim($row['program_name']))->first();

        return new Course([
            'course_name' => $row['course_name'],
            'course_code' => $row['course_code'],
            'short_name'  => $row['short_name'],
            'credit_hrs'  => $row['credit_hrs'],
            'program_id'  => $program->id, 
        ]);
    }

    /**
     * Excel Rows Validation Rules
     */
    public function rules(): array
    {
        return [
            'course_name'  => 'required|string|max:255',
            'course_code'  => 'required|string|unique:courses,course_code',
            'short_name'   => 'required|string|max:50',
            'credit_hrs'   => 'required',
            // FIXED: Changed target check database column from 'name' to 'program_name'
            'program_name' => 'required|exists:programs,program_name', 
        ];
    }

    /**
     * Custom Error Messages
     */
    public function customValidationMessages()
    {
        return [
            'course_code.unique'  => 'This Course Code is already in use. Please use a different code.',
            'program_name.exists' => 'This Program Name is not registered in the system. Please create the program first.',
        ];
    }
}