<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PLOs; // Model ka import bhi correct capitals ke sath
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PLOsController extends Controller // Class name matches file name exactly
{
    public function index()
    {
        $plos = PLOs::with('program')->orderBy('id', 'asc')->get();
        return response()->json(['status' => 'success', 'data' => $plos]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'plo_code' => [
                'required', 'string', 'max:50',
                Rule::unique('plos')->where(fn ($q) => $q->where('program_id', $request->program_id))
            ],
            'plo_description' => 'required|string',
            'program_id' => 'required|integer|exists:programs,id'
        ]);

        $plo = PLOs::create($request->all());
        return response()->json(['status' => 'success', 'message' => 'PLO created successfully', 'data' => $plo->load('program')], 201);
    }

    public function update(Request $request, $id)
    {
        $plo = PLOs::findOrFail($id);
        $request->validate([
            'plo_code' => [
                'required', 'string', 'max:50',
                Rule::unique('plos')->where(fn ($q) => $q->where('program_id', $request->program_id ?? $plo->program_id))->ignore($id)
            ],
            'plo_description' => 'required|string',
            'program_id' => 'required|integer|exists:programs,id'
        ]);

        $plo->update($request->all());
        return response()->json(['status' => 'success', 'message' => 'PLO updated successfully', 'data' => $plo->load('program')]);
    }

    public function destroy($id)
    {
        PLOs::findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'PLO deleted successfully']);
    }
}