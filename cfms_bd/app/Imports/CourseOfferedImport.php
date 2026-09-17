<?php

namespace App\Imports;

use App\Models\Course;
use App\Models\Session;
use App\Models\Program;
use App\Models\CourseOffered;
use Maatwebsite\Excel\Concerns\ToCollection;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Log; // Imported Log facade for warnings
use Exception;

class CourseOfferedImport implements ToCollection, WithHeadingRow
{
    public function collection(Collection $rows)
    {
        foreach ($rows as $row) {
            // Mapping based on WithHeadingRow standards
            $courseName  = trim($row['course'] ?? '');
            $courseCode  = trim($row['code'] ?? '');
            $shortName   = trim($row['short_name'] ?? '');
            $creditHrs   = trim($row['credit_hrs'] ?? ''); 
            $programName = trim($row['program'] ?? '');
            $sessionName = trim($row['session'] ?? '');

            if (empty($courseName) || empty($courseCode) || empty($sessionName)) {
                continue;
            }

            // ==========================================
            // STRICT CHECKING: Prevent Auto-Creation
            // ==========================================

            // 1. Strict Program Check
            // We only find the program, we do NOT create it if it's missing.
            if (!empty($programName)) {
                $program = Program::where('program_name', $programName)->first();
                if (!$program) {
                    Log::warning("Course Offered Import: Program '{$programName}' not found in database. Skipping row.");
                    continue;
                }
            }

            // 2. Strict Course Check (FIXED: Removed updateOrCreate)
            // We only find the course based on course_code.
            $course = Course::where('course_code', $courseCode)->first();
            
            if (!$course) {
                // If course does not exist, skip this row and do NOT create a fake course.
                Log::warning("Course Offered Import: Course with code '{$courseCode}' not found in courses table. Skipping row.");
                continue;
            }

            // 3. Find Session
            $session = Session::where('s_name', $sessionName)->first();

            if (!$session) {
                throw new Exception("Session '" . $sessionName . "' not found in database.");
            }

            // 4. Offer the course (This remains firstOrCreate to prevent duplicate offerings of the SAME course in the SAME session)
            CourseOffered::firstOrCreate([
                'course_id'  => $course->id,
                'session_id' => $session->id
            ]);
        }
    }
}