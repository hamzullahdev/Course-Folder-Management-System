<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Teacher;
use App\Models\CourseAllocation;
use App\Models\Teacher\Assessment;
use App\Models\Teacher\Question;
use App\Models\Teacher\Result;
use Barryvdh\DomPDF\Facade\Pdf;

class FcarController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $teacher = Teacher::where('user_id', $user->id)->first();

        if (!$teacher) {
            return response()->json(['success' => false, 'message' => 'Teacher profile not found.'], 403);
        }

        $allocations = CourseAllocation::with(['courseOffered.course', 'batch', 'session'])
            ->where('teacher_id', $teacher->id)
            ->get()
            ->map(function ($alloc) {
                return [
                    'allocation_id' => $alloc->id,
                    'course_name'   => $alloc->courseOffered->course->course_name ?? 'Unknown',
                    'course_code'   => $alloc->courseOffered->course->course_code ?? 'N/A',
                    'batch_name'    => $alloc->batch->batch_name ?? 'Unknown',
                    'section'       => $alloc->section,
                ];
            });

        return response()->json(['success' => true, 'allocations' => $allocations], 200);
    }

    public function generate(Request $request)
    {
        $request->validate(['allocation_id' => 'required|exists:course_allocations,id']);
        $allocationId = $request->allocation_id;

        // 1. Fetch Meta Info
        $allocation = CourseAllocation::with([
            'courseOffered.course.program.department', 
            'courseOffered.session', 
            'batch', 
            'teacher'
        ])->find($allocationId);

        $courseName = $allocation->courseOffered->course->course_name ?? 'N/A';
        $courseCode = $allocation->courseOffered->course->course_code ?? 'N/A';

        $meta = [
            'course_name'     => $courseName,
            'course_code'     => $courseCode,
            'teacher_name'    => $allocation->teacher->teacher_name ?? 'N/A',
            'department_name' => $allocation->courseOffered->course->program->department->dept_name ?? 'N/A',
            'batch_name'      => $allocation->batch->batch_name ?? 'N/A',
            'session_name'    => $allocation->courseOffered->session->s_name ?? 'N/A',
            'section'         => $allocation->section ?? 'N/A',
        ];

        // 2. Assessment Summary
        $assessments = Assessment::where('course_allocation_id', $allocationId)->get();
        $summary = ['quiz' => 0, 'assignment' => 0, 'mid' => 0, 'final' => 0];

        foreach ($assessments as $asmt) {
            $type = strtolower($asmt->type);
            if (str_contains($type, 'quiz')) $summary['quiz']++;
            elseif (str_contains($type, 'assignment')) $summary['assignment']++;
            elseif (str_contains($type, 'mid')) $summary['mid']++;
            elseif (str_contains($type, 'final')) $summary['final']++;
        }

        // 3. CLO Calculation
        $questionIds = Question::whereIn('assessment_id', $assessments->pluck('id'))->pluck('id')->toArray();
        $totalStudents = Result::whereIn('question_id', $questionIds)->distinct('student_id')->count('student_id');

        $cloMatrix = [];
        if ($totalStudents > 0) {
            $rawCloScores = DB::table('question_clo')
                ->join('questions', 'question_clo.question_id', '=', 'questions.id')
                ->join('clos', 'question_clo.clo_id', '=', 'clos.id')
                ->join('results', 'questions.id', '=', 'results.question_id')
                ->whereIn('questions.id', $questionIds)
                ->select(
                    'clos.clos_code',
                    DB::raw('SUM(results.obtained_marks) as total_obtained'),
                    DB::raw('SUM(questions.total_marks) as total_possible')
                )
                ->groupBy('clos.clos_code')
                ->get();

            foreach ($rawCloScores as $row) {
                $achievedPercent = $row->total_possible > 0 ? round(($row->total_obtained / $row->total_possible) * 100, 1) : 0;
                $cloMatrix[] = ['code' => $row->clos_code, 'achieved' => $achievedPercent . '%'];
            }
        }

        // 4. Grades & Performance (Aapki naye formula ke mutabiq)
        $gradesTally = ['A' => 0, 'A-' => 0, 'B+' => 0, 'B-' => 0, 'C+' => 0, 'C-' => 0, 'D+' => 0, 'D' => 0, 'F' => 0];
        $passed = 0; $failed = 0;

        if ($totalStudents > 0) {
            $totalPossibleAllocatedMarks = Question::whereIn('id', $questionIds)->sum('total_marks');
            if ($totalPossibleAllocatedMarks > 0) {
                $studentTotals = Result::whereIn('question_id', $questionIds)
                    ->select('student_id', DB::raw('SUM(obtained_marks) as total_marks'))
                    ->groupBy('student_id')->get();

                foreach ($studentTotals as $stud) {
                    $percent = ($stud->total_marks / $totalPossibleAllocatedMarks) * 100;
                    $grade = $this->calculateGradeTier($percent);
                    $gradesTally[$grade]++;
                    if ($grade === 'F') $failed++; else $passed++;
                }
            }
        }

        $passPercentage = $totalStudents > 0 ? round(($passed / $totalStudents) * 100) . '%' : '0%';

        // 5. Build HTML For PDF (No Blade File needed)
        $html = "
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; font-size: 14px; color: #333; }
                h2, h3 { color: #1E3C72; border-bottom: 2px solid #1E3C72; padding-bottom: 5px; }
                table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f4f4f4; }
                .meta-table td { border: none; padding: 4px 0; }
                .grade-box { display: inline-block; width: 100px; padding: 5px; margin: 5px; background: #eee; border-radius: 4px; text-align: center; font-weight: bold; }
            </style>
        </head>
        <body>
            <h2>Faculty Course Assessment Report (FCAR)</h2>
            <table class='meta-table'>
                <tr>
                    <td><b>Course:</b> {$meta['course_name']} ({$meta['course_code']})</td>
                    <td><b>Teacher:</b> {$meta['teacher_name']}</td>
                </tr>
                <tr>
                    <td><b>Batch/Session:</b> {$meta['batch_name']} | {$meta['session_name']}</td>
                    <td><b>Department:</b> {$meta['department_name']}</td>
                </tr>
                <tr>
                    <td><b>Section:</b> {$meta['section']}</td>
                </tr>
            </table>

            <h3>Assessment Summary</h3>
            <ul>
                <li>Quizzes: {$summary['quiz']}</li>
                <li>Assignments: {$summary['assignment']}</li>
                <li>Mid Exams: {$summary['mid']}</li>
                <li>Final Exams: {$summary['final']}</li>
            </ul>

            <h3>CLO Achievement Matrix</h3>
            <table>
                <tr><th>CLO Code</th><th>Achieved Percentage</th></tr>";
                foreach($cloMatrix as $clo) {
                    $html .= "<tr><td>{$clo['code']}</td><td>{$clo['achieved']}</td></tr>";
                }
        $html .= "
            </table>

            <h3>Student Performance</h3>
            <ul>
                <li>Total Students: {$totalStudents}</li>
                <li>Passed: {$passed}</li>
                <li>Failed: {$failed}</li>
                <li>Pass Percentage: {$passPercentage}</li>
            </ul>

            <h3>Grade Distribution</h3>
            <div>";
            foreach($gradesTally as $grade => $count) {
                $html .= "<div class='grade-box'>{$grade}: {$count}</div>";
            }
        $html .= "
            </div>
        </body>
        </html>";

        // Generate PDF and return as Download stream
        $pdf = Pdf::loadHTML($html);
        $fileName = "{$courseName} - {$courseCode}.pdf";

        return response($pdf->output(), 200)
            ->header('Content-Type', 'application/pdf')
            ->header('Content-Disposition', 'attachment; filename="' . $fileName . '"');
    }

    // Aapka naya Grading Function
    private function calculateGradeTier($score)
    {
        if ($score >= 85) return 'A';
        if ($score >= 80) return 'A-';
        if ($score >= 75) return 'B+';
        if ($score >= 70) return 'B-';
        if ($score >= 65) return 'C+';
        if ($score >= 60) return 'C-';
        if ($score >= 55) return 'D+';
        if ($score >= 50) return 'D';
        return 'F';
    }
}