<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Student;
use App\Models\Teacher\Result;
use App\Models\Enrollment;
use Illuminate\Http\Request;
use Exception;

class StudentDashboardController extends Controller
{
    public function myResults(Request $request)
    {
        try {
            // 1. Fetch Logged-in Student
            $student = Student::with('batch', 'program')->where('user_id', $request->user()->id)->first();

            if (!$student) {
                return response()->json(['success' => false, 'message' => 'Student profile not found.'], 404);
            }

            // 2. Fetch Unique Enrolled Courses & Sessions safely
            $enrollments = Enrollment::with(['courseOffered.course', 'courseOffered.session'])
                ->where('student_id', $student->id)
                ->get();
                
            $enrolledCourses = [];
            $courseSessions = []; 
            
            foreach ($enrollments as $enrollment) {
                $course = $enrollment->courseOffered->course ?? null;
                $session = $enrollment->courseOffered->session ?? null;
                
                if ($course && !isset($enrolledCourses[$course->id])) {
                    $enrolledCourses[$course->id] = [
                        'id' => $course->id,
                        'course_name' => $course->course_name,
                    ];
                    $courseSessions[$course->id] = $session ? ($session->s_name ?? $session->name ?? 'N/A') : 'N/A';
                }
            }

            // 3. Fetch All Results
            $results = Result::with([
                'question.assessment.courseAllocation.courseOffered.course'
            ])
            ->where('student_id', $student->id)
            ->get();

            // 4. Aggregate Marks Per Subject
            $aggregatedResults = [];

            foreach ($results as $result) {
                $question = $result->question ?? null;
                $assessment = $question ? $question->assessment : null;
                $allocation = $assessment ? $assessment->courseAllocation : null;
                $offered = $allocation ? $allocation->courseOffered : null;
                $course = $offered ? $offered->course : null;

                // Agar chain mein koi bhi cheez missing hai toh skip kardo (Crash se bachne ke liye)
                if (!$course) continue;

                $c_id = $course->id;

                if (!isset($aggregatedResults[$c_id])) {
                    $aggregatedResults[$c_id] = [
                        'course_id'      => $c_id,
                        'subject'        => $course->course_name,
                        'batch'          => $student->batch ? ($student->batch->batch_name ?? $student->batch->name ?? 'N/A') : 'N/A',
                        'session'        => $courseSessions[$c_id] ?? 'N/A',
                        'obtained_marks' => 0,
                    ];
                }

                // Sirf obtained marks ko plus karna
                $aggregatedResults[$c_id]['obtained_marks'] += is_numeric($result->obtained_marks) ? (float)$result->obtained_marks : 0;
            }

            // 5. Calculate Final Grades (Max Marks strictly 100)
            $finalResults = array_map(function ($item) {
                $obtained = $item['obtained_marks'];
                
                // ✨ FIX: Total Marks 100 set kar diye gaye hain
                $max = 100; 
                
                $percentage = ($obtained / $max) * 100;
                
                // ✨ FIX: Aapka diya gaya Grading Formula
                $grade = 'F';
                if ($percentage >= 85) { $grade = 'A'; }
                elseif ($percentage >= 80) { $grade = 'A-'; }
                elseif ($percentage >= 75) { $grade = 'B+'; }
                elseif ($percentage >= 70) { $grade = 'B-'; }
                elseif ($percentage >= 65) { $grade = 'C+'; }
                elseif ($percentage >= 60) { $grade = 'C-'; }
                elseif ($percentage >= 55) { $grade = 'D+'; }
                elseif ($percentage >= 50) { $grade = 'D'; }

                $item['max_marks'] = $max; // Frontend par 100 bhejne ke liye
                $item['grade'] = $grade;
                
                return $item;
            }, array_values($aggregatedResults));

            return response()->json([
                'success' => true,
                'student_name' => $student->std_name,
                'reg_no' => $student->reg_no,
                'enrolled_courses' => array_values($enrolledCourses),
                'results' => $finalResults
            ]);
            
        } catch (Exception $e) {
            return response()->json([
                'success' => false, 
                'message' => 'Backend Error: ' . $e->getMessage()
            ], 500);
        }
    }
}