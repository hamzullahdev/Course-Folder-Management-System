<?php

namespace App\Imports;

use App\Models\Student;
use App\Models\Program;
use App\Models\Session;
use App\Models\Course;
use App\Models\CourseOffered;
use App\Models\Enrollment;
use App\Models\Batch; 
use App\Models\Department; 

use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;

class EnrollmentImport implements ToCollection, WithHeadingRow
{
    public function collection(Collection $rows)
    {
        foreach ($rows as $row) {
            
            $regNo       = trim($row['regno'] ?? $row['reg_no'] ?? '');
            $studentName = trim($row['name'] ?? '');
            $deptName    = trim($row['department'] ?? ''); 
            $programName = trim($row['program'] ?? '');
            $batchName   = trim($row['batch'] ?? ''); 
            $sessionName = trim($row['session'] ?? '');
            $sectionName = trim($row['section'] ?? '');
            $subjectName = trim($row['subject'] ?? ''); 

            if (empty($regNo) || empty($subjectName) || empty($sessionName) || empty($batchName)) {
                continue;
            }

            $department = Department::firstOrCreate(
                ['dept_name' => $deptName]
            );

            $program = Program::firstOrCreate(
                ['program_name' => $programName],
                ['department_id' => $department->id] 
            );

            $batch = Batch::firstOrCreate(
                ['batch_name' => $batchName],
                ['program_id' => $program->id]
            );

            $session = Session::firstOrCreate(
                ['s_name' => $sessionName]
            );

            $course = Course::firstOrCreate(
                [
                    'course_name' => $subjectName,
                    'program_id'  => $program->id
                ],
                [
                    'course_code' => 'SUB-' . strtoupper(substr(md5($subjectName), 0, 5)), 
                    'short_name'  => strtoupper(substr($subjectName, 0, 3)),
                    'credit_hrs'  => '3'
                ]
            );

            $courseOffered = CourseOffered::firstOrCreate([
                'course_id'  => $course->id,
                'session_id' => $session->id
            ]);

            $student = Student::updateOrCreate(
                ['reg_no' => $regNo],
                [
                    'std_name'   => $studentName,
                    'program_id' => $program->id,
                    'batch_id'   => $batch->id
                ]
            );

            Enrollment::firstOrCreate([
                'student_id'        => $student->id,
                'course_offered_id' => $courseOffered->id,
                'section'           => $sectionName
            ]);
        }
    }
}