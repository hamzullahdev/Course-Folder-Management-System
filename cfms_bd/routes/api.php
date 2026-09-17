<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\Admin\DepartmentController;
use App\Http\Controllers\Admin\ProgramController;
use App\Http\Controllers\Admin\PLOsController;
use App\Http\Controllers\Admin\CourseController;
use App\Http\Controllers\Admin\CloController; 
use App\Http\Controllers\Admin\BatchController;
use App\Http\Controllers\Admin\SessionController;
use App\Http\Controllers\Admin\StudentController;
use App\Http\Controllers\Admin\TeacherController;
use App\Http\Controllers\Admin\CourseOfferedController;
use App\Http\Controllers\Admin\EnrollmentController;
use App\Http\Controllers\Admin\CourseAllocationController;
use App\Http\Controllers\Admin\FolderController;
use App\Http\Controllers\Admin\SubFolderController;
use App\Http\Controllers\Admin\FileController;
use App\Http\Controllers\Admin\CourseCloSessionController;
use App\Http\Controllers\Admin\ReportController;

// Teacher Controllers
use App\Http\Controllers\Teacher\MyCoursesController;
use App\Http\Controllers\Teacher\FileSubmissionController;
use App\Http\Controllers\Teacher\AssessmentController; // ✨ FIX: Yahan se // hata diya hai
use App\Http\Controllers\Teacher\QuestionController;
use App\Http\Controllers\Teacher\QuestionCloMappingController;
use App\Http\Controllers\Teacher\ResultController;
use App\Http\Controllers\Teacher\ViewClosController;
use App\Http\Controllers\Teacher\ClosPlosMappingController;
use App\Http\Controllers\Teacher\ChecklistController;
use App\Http\Controllers\Teacher\ChangePasswordController;
use App\Http\Controllers\Teacher\FcarController; // ✨ FIX: FCAR Controller import kiya

//Student Controllers
use App\Http\Controllers\Student\StudentDashboardController;

// ==============================================================
// PUBLIC ROUTES (No Token Needed Automatically)
// ==============================================================
Route::post('/login', [UserController::class, 'login']);

Route::get('/admin/reports/{id}/download-zip', [ReportController::class, 'downloadZip']);
Route::get('/teacher/allocations/{id}/download-zip', [MyCoursesController::class, 'downloadZip']);

// ==============================================================
// PROTECTED ROUTES (Requires Sanctum Authentication)
// ==============================================================
Route::middleware('auth:sanctum')->group(function () {
    
    Route::post('/logout', [UserController::class, 'logout']);

    // --- ADMIN ROUTES ---
    Route::prefix('admin')->group(function () {
        Route::apiResource('department', DepartmentController::class);
        Route::apiResource('program', ProgramController::class);
        Route::apiResource('plo', PLOsController::class);
        Route::apiResource('batches', BatchController::class);
        Route::apiResource('sessions', SessionController::class);

        Route::get('/reports/filters', [ReportController::class, 'getFilters']);
        Route::get('/reports', [ReportController::class, 'getReports']);
        Route::post('/reports/{id}/accept', [ReportController::class, 'acceptAllocation']);
        Route::post('/reports/{id}/reject', [ReportController::class, 'rejectAllocation']);
        Route::get('/reports/{id}/files', [ReportController::class, 'getAllocationFiles']); 
        
        Route::get('/course', [CourseController::class, 'index']);
        Route::post('/course', [CourseController::class, 'store']);
        Route::put('/course/{id}', [CourseController::class, 'update']);
        Route::delete('/course/{id}', [CourseController::class, 'destroy']);
        Route::post('/course/import', [CourseController::class, 'import']);

        Route::apiResource('clos', CloController::class);
        Route::apiResource('course-clo-sessions', CourseCloSessionController::class);

        Route::post('/students/import', [StudentController::class, 'import']);
        Route::get('/students', [StudentController::class, 'index']);          
        Route::get('/students/{id}', [StudentController::class, 'show']);      
        Route::put('/students/{id}', [StudentController::class, 'update']);    
        Route::delete('/students/{id}', [StudentController::class, 'destroy']);

        Route::get('/teachers', [TeacherController::class, 'index']);
        Route::put('/teachers/{id}', [TeacherController::class, 'update']);
        Route::delete('/teachers/{id}', [TeacherController::class, 'destroy']);
        Route::post('/teachers/import', [TeacherController::class, 'import']);

        Route::get('/course-offered', [CourseOfferedController::class, 'index']);
        Route::post('/course-offered/import', [CourseOfferedController::class, 'import']);
        Route::put('/course-offered/{id}', [CourseOfferedController::class, 'update']);
        Route::delete('/course-offered/{id}', [CourseOfferedController::class, 'destroy']);

        Route::get('/enrollments', [EnrollmentController::class, 'index']);
        Route::post('/enrollments/import', [EnrollmentController::class, 'import']);
        Route::put('/enrollments/{id}', [EnrollmentController::class, 'update']);
        Route::delete('/enrollments/{id}', [EnrollmentController::class, 'destroy']);

        Route::get('/course-allocations', [CourseAllocationController::class, 'index']);
        Route::post('/course-allocations/import', [CourseAllocationController::class, 'import']);
        Route::put('/course-allocations/{id}', [CourseAllocationController::class, 'update']);
        Route::delete('/course-allocations/{id}', [CourseAllocationController::class, 'destroy']);

        Route::apiResource('folders', FolderController::class);
        Route::get('/parent-folders', [SubFolderController::class, 'parentFolders']); 
        Route::apiResource('subfolders', SubFolderController::class);

        Route::get('/valid-file-folders', [FileController::class, 'validFolders']);
        Route::apiResource('files', FileController::class);
    });

    // --- TEACHER SPECIFIC ROUTES ---
    Route::prefix('teacher')->group(function () {
        
        Route::get('/my-courses', [MyCoursesController::class, 'index']);
        Route::post('/my-courses/{id}/submit', [MyCoursesController::class, 'submitCourse']);
        
        // File Submissions
        Route::get('/folders', [FileSubmissionController::class, 'getFolders']);
        Route::get('/folders/{id}/files', [FileSubmissionController::class, 'getFilesByFolder']);
        Route::get('/allocations/{id}/submissions', [FileSubmissionController::class, 'getSubmissions']);
        Route::post('/submissions/upload', [FileSubmissionController::class, 'uploadFile']);

        // Assessments (Yeh ab fully work karenge)
        Route::get('/assessments/{allocationId}', [AssessmentController::class, 'index']);
        Route::post('/assessments', [AssessmentController::class, 'store']);
        Route::delete('/assessments/{id}', [AssessmentController::class, 'destroy']);
        Route::put('/assessments/{id}', [AssessmentController::class, 'update']);

        // Pure Question CRUD
        Route::get('assessments/{assessmentId}/questions', [QuestionController::class, 'index']);
        Route::post('questions', [QuestionController::class, 'store']);
        Route::put('questions/{id}', [QuestionController::class, 'update']);
        Route::delete('questions/{id}', [QuestionController::class, 'destroy']);
        
        // Question-CLO Mapping
        Route::get('questions/{questionId}/clos', [QuestionCloMappingController::class, 'showMappedClos']);
        Route::post('question-clo/map', [QuestionCloMappingController::class, 'mapClos']);
        Route::delete('question-clo/{questionId}/remove', [QuestionCloMappingController::class, 'removeMappings']);

        // Results
        Route::get('allocations/{allocationId}/students', [ResultController::class, 'getStudents']);
        Route::get('questions/{questionId}/results', [ResultController::class, 'index']);
        Route::post('results/bulk', [ResultController::class, 'storeBulk']);
        Route::put('results/{id}', [ResultController::class, 'update']);
        Route::delete('results/{id}', [ResultController::class, 'destroy']);

        // View CLOs
        Route::get('course/{courseId}/clos', [ViewClosController::class, 'getClosByCourse']);

        // CLO-PLO Mapping
        Route::get('course/{courseId}/clo-plo-mapping', [ClosPlosMappingController::class, 'getMappingData']);
        Route::post('clo-plo-mapping', [ClosPlosMappingController::class, 'saveMapping']);
        
        Route::get('allocations/{allocationId}/checklist', [ChecklistController::class, 'getChecklist']);
        Route::post('change-password', [ChangePasswordController::class, 'updatePassword']);

        // Teacher Specific Routes ke andar paste karein:
        Route::get('/fcar/allocations', [\App\Http\Controllers\Teacher\FcarController::class, 'index']);
        Route::post('/fcar/generate', [\App\Http\Controllers\Teacher\FcarController::class, 'generate']);
    });

    // --- STUDENT SPECIFIC ROUTES ---
    Route::prefix('student')->group(function () {
        Route::get('/my-results', [StudentDashboardController::class, 'myResults']);
    });
});

// use App\Models\Student;
// use App\Models\User;
// use Illuminate\Support\Facades\Hash;
// // Yahan se 'use Exception;' hata diya gaya hai

// Route::get('/generate-old-students-accounts', function () {
//     try {
//         // Un students ko nikalna jinka user_id NULL hai
//         $students = Student::whereNull('user_id')->get();
//         $count = 0;

//         foreach ($students as $student) {
//             $firstName = strtolower(explode(' ', trim($student->std_name))[0]);
//             $email = $firstName . '.' . $student->id . '@student.com';

//             $user = User::firstOrCreate(
//                 ['email' => $email], 
//                 [
//                     'password' => Hash::make('password123'), 
//                     'role'     => 'student',
//                 ]
//             );

//             $student->user_id = $user->id;
//             $student->save();
            
//             $count++;
//         }

//         return response()->json([
//             'success' => true,
//             'message' => "$count old students ke accounts successfully link aur create ho gaye hain!"
//         ]);

//     } catch (\Exception $e) { // Yahan \Exception laga diya hai
//         return response()->json([
//             'success' => false,
//             'error_message' => $e->getMessage()
//         ]);
//     }
// });