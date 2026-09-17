<?php

namespace App\Imports;

use App\Models\CourseAllocation;
use App\Models\Teacher;
use App\Models\Course;
use App\Models\CourseOffered;
use App\Models\Session;
use App\Models\Batch;
use App\Models\Program;
use App\Models\Department;

use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log;

class CourseAllocationImport implements ToCollection, WithHeadingRow
{
    public function collection(Collection $rows)
    {
        foreach ($rows as $row) {
            // Excel headers mapping
            $batchName   = trim($row['batch'] ?? '');
            $sectionName = trim($row['section'] ?? '');
            $courseName  = trim($row['course'] ?? '');
            $teacherName = trim($row['teacher_name'] ?? '');
            $sessionName = trim($row['session'] ?? '');
            $programName = trim($row['program'] ?? '');

            if (empty($batchName) || empty($courseName) || empty($teacherName) || empty($sessionName)) {
                continue;
            }

            // ==========================================
            // Fetch Existing Teacher
            // ==========================================
            $teacher = Teacher::where('teacher_name', $teacherName)->first();
            
            if (!$teacher) {
                Log::warning("Course Allocation Import: Teacher '{$teacherName}' not found in database.");
                continue;
            }

            // 1. Program Setup
            $department = Department::firstOrCreate(['dept_name' => 'General Department']);
            $program = Program::firstOrCreate(
                ['program_name' => $programName],
                ['department_id' => $department->id]
            );

            // 2. Batch Setup
            $batch = Batch::firstOrCreate(
                ['batch_name' => $batchName],
                ['program_id' => $program->id]
            );

            // 3. Session Setup
            $session = Session::firstOrCreate(
                ['s_name' => $sessionName],
                ['start_date' => now(), 'end_date' => now()->addMonths(6)]
            );

            // ==========================================
            // FIXED LOGIC: Strict Course Checking
            // ==========================================
            
            // 4A. Strictly check if the Course exists in the courses table
            $course = Course::where('course_name', $courseName)->first();
            
            if (!$course) {
                // If course is not in the database, skip this row and do NOT create it
                Log::warning("Course Allocation Import: Course '{$courseName}' not found in the courses table. Skipping allocation.");
                continue;
            }

            // 4B. Strictly check if this course is currently Offered in the given Session
            $courseOffered = CourseOffered::where('course_id', $course->id)
                                          ->where('session_id', $session->id)
                                          ->first();

            if (!$courseOffered) {
                // If the course is not offered in this session, skip this row
                Log::warning("Course Allocation Import: Course '{$courseName}' is not officially offered in session '{$sessionName}'. Skipping allocation.");
                continue;
            }

            // 5. Final Course Allocation Record (Using updateOrCreate to prevent duplicate allocations)
            CourseAllocation::updateOrCreate([
                'teacher_id'        => $teacher->id,
                'course_offered_id' => $courseOffered->id,
                'session_id'        => $session->id,
                'batch_id'          => $batch->id,
                'section'           => $sectionName
            ], [
                'status' => 'in progess',
                'reason' => 'Initial Allocation'
            ]);
        }
    }
}