<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Teacher\Question;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class QuestionCloMappingController extends Controller
{
    // 1. Get all mapped CLOs for a specific question
    public function showMappedClos($questionId)
    {
        $question = Question::with('clos')->findOrFail($questionId);
        return response()->json(['success' => true, 'data' => $question->clos]);
    }

    // 2. Save or Sync CLO mappings for a question
    public function mapClos(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'question_id' => 'required|exists:questions,id',
            'clo_ids'     => 'required|array',
            'clo_ids.*'   => 'exists:clos,id'
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $question = Question::findOrFail($request->question_id);
        
        // sync() automatically removes old relations and attaches new ones
        $question->clos()->sync($request->clo_ids);

        return response()->json([
            'success' => true, 
            'message' => 'CLOs mapped to question successfully.',
            'data'    => $question->load('clos')
        ]);
    }

    // 3. Remove all CLO mappings from a specific question (Remove Mapping)
    public function removeMappings($questionId)
    {
        $question = Question::findOrFail($questionId);
        
        // detach() without arguments removes all pivot entries for this question
        $question->clos()->detach();

        return response()->json(['success' => true, 'message' => 'All CLO mappings removed from this question.']);
    }
}