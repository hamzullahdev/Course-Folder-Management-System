<?php



namespace App\Http\Controllers\Admin;



use App\Http\Controllers\Controller;

use Illuminate\Http\Request;

use Illuminate\Support\Facades\DB;

use Illuminate\Support\Facades\Carbon;

use App\Models\CourseAllocation;

use App\Models\Teacher\FileSubmission;

use App\Models\Folder;

use ZipArchive;

use Exception;



class ReportController extends Controller

{

    public function getAllocationFiles($id)
    {
        try {
            $submissions = FileSubmission::with(['file'])->where('course_allocation_id', $id)->get();
            $data = $submissions->map(function ($sub) {
                return [
                    'id' => $sub->id,
                    'file_path' => $sub->file_path,
                    'file_name' => $sub->file->file_name ?? basename($sub->file_path),
                ];
            });
            return response()->json(['success' => true, 'data' => $data], 200);
        } catch (Exception $e) {
            return response()->json(['success' => false, 'message' => 'Failed to fetch files.'], 500);
        }
    }
    /**

     * Get all master data required for the frontend dropdown filters.

     */

    public function getFilters()

    {

        try {

            $departments = DB::table('departments')->orderBy('dept_name', 'asc')->get();

            $programs = DB::table('programs')->orderBy('program_name', 'asc')->get();

            $sessions = DB::table('sessions')->orderBy('s_name', 'desc')->get();

            $batches = DB::table('batches')->orderBy('batch_name', 'desc')->get();

            $teachers = DB::table('teachers')->orderBy('teacher_name', 'asc')->get();

            

            // Extract distinct sections from allocations

            $sections = DB::table('course_allocations')

                ->whereNotNull('section')

                ->distinct()

                ->pluck('section');



            return response()->json([

                'success' => true,

                'data' => [

                    'departments' => $departments,

                    'programs' => $programs,

                    'sessions' => $sessions,

                    'batches' => $batches,

                    'teachers' => $teachers,

                    'sections' => $sections

                ]

            ], 200);

        } catch (Exception $e) {

            return response()->json(['success' => false, 'message' => 'Failed to load filters.', 'error' => $e->getMessage()], 500);

        }

    }



    /**

     * Get the dynamic report matrix based on applied filters.

     */

    public function getReports(Request $request)

    {

        try {

            $completionContext = $request->query('completion_context', 'complete');



            $query = CourseAllocation::with([

                'teacher',

                'courseOffered.course.program.department',

                'session',

                'batch'

            ]);



            // Apply Filters via Relationships

            if ($request->filled('department_id')) {

                $query->whereHas('courseOffered.course.program', function($q) use ($request) {

                    $q->where('department_id', $request->department_id);

                });

            }

            if ($request->filled('program_id')) {

                $query->where('batch_id', function($q) use ($request) {

                    $q->select('id')->from('batches')->where('program_id', $request->program_id)->limit(1);

                });

            }

            if ($request->filled('session_id')) {

                $query->where('session_id', $request->session_id);

            }

            if ($request->filled('batch_id')) {

                $query->where('batch_id', $request->batch_id);

            }

            if ($request->filled('section')) {

                $query->where('section', $request->section);

            }

            if ($request->filled('teacher_id')) {

                $query->where('teacher_id', $request->teacher_id);

            }



            // Status Logic

            if ($completionContext === 'complete') {

                $query->whereIn('status', ['approved', 'submitted']);

            } else {

                $query->whereIn('status', ['in progress','Active','active', 'rejected']);

            }



            $allocations = $query->get();



            // =========================================================

            // Calculate Semesters Dynamically using the new 3-Semester Logic

            // =========================================================

            $processedRecords = $allocations->map(function ($row) {

                $semesterText = '1st';

                $batchName = $row->batch->batch_name ?? '';

                $sessionName = $row->session->s_name ?? '';



                if (!empty($batchName) && !empty($sessionName)) {

                    preg_match('/\d{4}/', $batchName, $batchMatches);

                    $admissionYear = isset($batchMatches[0]) ? (int)$batchMatches[0] : null;



                    if ($admissionYear) {

                        preg_match('/\d{4}/', $sessionName, $sessionMatches);

                        $sessionYear = isset($sessionMatches[0]) ? (int)$sessionMatches[0] : Carbon::now()->year;

                        

                        $yearDiff = $sessionYear - $admissionYear;

                        $semester = 1;

                        

                        $sLower = strtolower($sessionName);

                        $bLower = strtolower($batchName);

                        

                        // Main semester calculation based on Session type

                        if (str_contains($sLower, 'fall')) {

                            $semester = ($yearDiff * 2) + 1;

                        } elseif (str_contains($sLower, 'spring')) {

                            $semester = ($yearDiff * 2);

                        } elseif (str_contains($sLower, 'summer')) {

                            $semester = ($yearDiff * 2);

                        } else {

                            $semester = ($yearDiff * 2) + 1; // Default

                        }

                        

                        // Adjust if admission was in Spring

                        if (str_contains($bLower, 'spring')) {

                            $semester += 1;

                        }

                        

                        // Safety clamp

                        if ($semester < 1) {

                            $semester = 1;

                        }

                        

                        // Determine proper suffix

                        $suffix = "th";

                        if ($semester % 10 == 1 && $semester % 100 != 11) {

                            $suffix = "st";

                        } elseif ($semester % 10 == 2 && $semester % 100 != 12) {

                            $suffix = "nd";

                        } elseif ($semester % 10 == 3 && $semester % 100 != 13) {

                            $suffix = "rd";

                        }

                        

                        // Format the final output string

                        if (str_contains($sLower, 'summer')) {

                            $semesterText = $semester . $suffix . " (Summer)";

                        } else {

                            $semesterText = $semester . $suffix;

                        }

                    }

                }

                

                // Append custom attribute safely

                $row->setAttribute('semester_text', $semesterText);

                return $row;

            });



            return response()->json(['success' => true, 'data' => $processedRecords], 200);



        } catch (Exception $e) {

            return response()->json(['success' => false, 'message' => 'Failed to load report data.', 'error' => $e->getMessage()], 500);

        }

    }



    /**

     * Mark an allocation as Approved.

     */

    public function acceptAllocation($id)

    {

        try {

            $allocation = CourseAllocation::findOrFail($id);

            $allocation->update([

                'status' => 'approved',

                'reason' => null

            ]);

            return response()->json(['success' => true, 'message' => 'Course package approved successfully.'], 200);

        } catch (Exception $e) {

            return response()->json(['success' => false, 'message' => 'Failed to approve package.'], 500);

        }

    }



    /**

     * Mark an allocation as Rejected with a reason.

     */

    public function rejectAllocation(Request $request, $id)

    {

        $request->validate(['reason' => 'required|string']);

        try {

            $allocation = CourseAllocation::findOrFail($id);

            $allocation->update([

                'status' => 'rejected',

                'reason' => $request->reason

            ]);

            return response()->json(['success' => true, 'message' => 'Course package rejected with feedback log.'], 200);

        } catch (Exception $e) {

            return response()->json(['success' => false, 'message' => 'Failed to reject package.'], 500);

        }

    }



    /**

     * Download the Aggregated ZIP Package.

     */

    // ✨ FIX: Request object pass kiya hai token capture karne ke liye
    public function downloadZip(Request $request, $id)
    {
        // 1. Manually check the token from URL
        $token = $request->query('token');
        if (!$token || !\Laravel\Sanctum\PersonalAccessToken::findToken($token)) {
            abort(401, 'Unauthorized file access. Invalid Token.');
        }

        // 2. Normal zip code
        $allocation = CourseAllocation::with(['courseOffered.course', 'session', 'batch'])->findOrFail($id);

        $courseName = $allocation->courseOffered->course->course_name ?? 'Course';
        $semesterDisplay = 'Package';
        $sectionToken = !empty($allocation->section) ? '_' . $allocation->section : '';
        
        $folderTitleString = $courseName . '-' . $semesterDisplay . $sectionToken;
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
        abort(500, 'Could not compile compressed package framework zip.');
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

}