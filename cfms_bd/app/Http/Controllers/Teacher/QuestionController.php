<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Teacher\Question;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class QuestionController extends Controller
{
    // 1. Get all questions (Updated to handle 'all' for Grid Default Load)
    public function index($assessmentId = 'all')
    {
        if ($assessmentId === 'all') {
            // By default, sare questions aur unke mapped CLOs uthao
            $questions = Question::with('clos')->get();
        } else {
            // Selected assessment ke questions uthao
            $questions = Question::with('clos')->where('assessment_id', $assessmentId)->get();
        }
        return response()->json(['success' => true, 'data' => $questions]);
    }

    // 2. Store a new question
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'assessment_id' => 'required|exists:assessments,id',
            'question_text' => 'required|string',
            'total_marks'   => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $question = Question::create([
            'assessment_id' => $request->assessment_id,
            'question_text' => $request->question_text,
            'total_marks'   => $request->total_marks,
        ]);

        return response()->json([
            'success' => true, 
            'message' => 'Question created successfully.',
            'data'    => $question
        ]);
    }

    // 3. Update an existing question
    public function update(Request $request, $id)
    {
        $question = Question::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'question_text' => 'required|string',
            'total_marks'   => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $question->update([
            'question_text' => $request->question_text,
            'total_marks'   => $request->total_marks,
        ]);

        return response()->json([
            'success' => true, 
            'message' => 'Question updated successfully.',
            'data'    => $question->load('clos')
        ]);
    }

    // 4. Delete a question
    public function destroy($id)
    {
        $question = Question::findOrFail($id);
        $question->delete(); 

        return response()->json(['success' => true, 'message' => 'Question deleted successfully.']);
    }
}