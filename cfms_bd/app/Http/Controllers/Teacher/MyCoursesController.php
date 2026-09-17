<?php



namespace App\Http\Controllers\Teacher;



use App\Http\Controllers\Controller;

use App\Models\CourseAllocation;

use App\Models\Teacher;

use App\Models\Session; // YAHAN SESSION MODEL IMPORT KRNA ZAROORI HAI
use App\Models\Teacher\FileSubmission; // ✨ IMPORTED
use Illuminate\Support\Facades\DB;     // ✨ IMPORTED
use ZipArchive;                        // ✨ IMPORTED
use Illuminate\Http\Request;

use Exception;



class MyCoursesController extends Controller

{

    /**

     * Retrieve courses allocated to the currently authenticated teacher.

     */

    public function index(Request $request)

    {

        try {

            $user = $request->user();

            $teacher = Teacher::where('user_id', $user->id)->first();



            if (!$teacher) {

                return response()->json([

                    'success' => false,

                    'message' => 'Teacher profile not found for this user.'

                ], 404);

            }



            // 1. Fetch allocations strictly for this teacher with all required relations

            // ✨ Yahan withCount add kiya gaya hai taake progress bar ke liye total uploaded files ka count aa sake!

            $allocations = CourseAllocation::with([

                'courseOffered.course.program.department',

                'session',

                'batch'

            ])

            ->withCount('fileSubmissions') // <-- ✨ YEH LINE ADD KI HAI (Agar relation ka naam sirf 'submissions' hai, toh withCount('submissions') kar lein)

            ->where('teacher_id', $teacher->id)->get();



            // 2. Database se SAARE sessions fetch karein (Naye se purane ki tarteeb mein)

            // Taake dropdown mein sab show hon, chahay course allocate ho ya na ho

            $sessions = Session::orderBy('id', 'desc')->get();



            return response()->json([

                'success'  => true,

                'sessions' => $sessions,

                'data'     => $allocations

            ], 200);



        } catch (Exception $e) {

            return response()->json([

                'success' => false,

                'message' => 'Failed to fetch your allocated courses.',

                'error'   => $e->getMessage()

            ], 500);

        }

    }

    // ✨ FIX: Request object add kiya aur token manually verify kiya
    public function downloadZip(Request $request, $id)
    {
        // 1. Check if valid token exists in the URL
        $token = $request->query('token');
        if (!$token || !\Laravel\Sanctum\PersonalAccessToken::findToken($token)) {
            abort(401, 'Unauthorized file access. Invalid Token.');
        }

        // 2. Proceed with ZIP creation
        $allocation = CourseAllocation::with(['courseOffered.course', 'session', 'batch'])->findOrFail($id);

        $courseName = $allocation->courseOffered->course->course_name ?? 'Course';
        $sectionToken = !empty($allocation->section) ? '_' . $allocation->section : '';
        
        $folderTitleString = $courseName . '-Package' . $sectionToken;
        $zipFileName = preg_replace('/[^A-Za-z0-9_\-]/', '_', $folderTitleString) . '_Package.zip';
        $zipStoragePath = storage_path('app/public/' . $zipFileName);

        $zipEngine = new ZipArchive;
        if ($zipEngine->open($zipStoragePath, ZipArchive::CREATE | ZipArchive::OVERWRITE) === true) {
            
            $baseFolder = preg_replace('/[^A-Za-z0-9_\-]/', '_', $folderTitleString) . '/';
            $zipEngine->addEmptyDir($baseFolder);

            $uploadedSubmissions = FileSubmission::where('course_allocation_id', $id)->with(['file.folder'])->get();
            $allFoldersMap = DB::table('folders')->get()->keyBy('folder_id');

            foreach ($allFoldersMap as $folder) {
                $dirRoute = $this->buildFolderPath($folder->folder_id, $allFoldersMap);
                $zipEngine->addEmptyDir($baseFolder . $dirRoute);
            }

            foreach ($uploadedSubmissions as $submission) {
                $rawPath = $submission->file_path; 
                $absoluteStorageFileSource = storage_path('app/public/' . $rawPath);

                if (file_exists($absoluteStorageFileSource) && !empty($submission->file)) {
                    $cleanFilenameWithShortcode = basename($rawPath);
                    $folderId = $submission->file->folder_id ?? null;

                    if ($folderId && isset($allFoldersMap[$folderId])) {
                        $targetDirectoryRoute = $this->buildFolderPath($folderId, $allFoldersMap);
                        $nestedInternalZipPath = $baseFolder . $targetDirectoryRoute . '/' . $cleanFilenameWithShortcode;
                        $zipEngine->addFile($absoluteStorageFileSource, $nestedInternalZipPath);
                    }
                }
            }
            $zipEngine->close();
            return response()->download($zipStoragePath)->deleteFileAfterSend(true);
        }
        abort(500, 'Could not compile compressed package.');
    }

    private function buildFolderPath($folderId, $foldersMap)
    {
        $pathSegments = [];
        $currentId = $folderId;
        while ($currentId !== null && isset($foldersMap[$currentId])) {
            $folder = $foldersMap[$currentId];
            array_unshift($pathSegments, $folder->folder_name);
            $currentId = $folder->parent_id;
        }
        return implode('/', $pathSegments);
    }

    public function submitCourse(Request $request, $id)
    {
        try {
            $allocation = CourseAllocation::findOrFail($id);
            $allocation->update([
                'status' => 'submitted',
                'reason' => ''
            ]);
            
            return response()->json([
                'success' => true, 
                'message' => 'Course submitted successfully.'
            ], 200);
            
        } catch (Exception $e) {
            return response()->json([
                'success' => false, 
                'message' => 'Failed to submit.', 
                'error' => $e->getMessage()
            ], 500);
        }
    }
}



