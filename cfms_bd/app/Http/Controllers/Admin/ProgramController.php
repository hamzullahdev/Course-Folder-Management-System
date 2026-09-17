<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Program;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProgramController extends Controller
{
    public function index()
    {
        $programs = Program::with('department')->get();
        return response()->json(['status' => 'success', 'data' => $programs]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'program_name' => 'required|string|max:255',
            'department_id' => 'required|exists:departments,id'
        ]);

        $program = Program::create($request->all());
        return response()->json(['status' => 'success', 'message' => 'Program created successfully', 'data' => $program], 201);
    }

    public function update(Request $request, $id)
    {
        $program = Program::findOrFail($id);
        $request->validate([
            'program_name' => 'required|string|max:255',
            'department_id' => 'required|exists:departments,id'
        ]);

        $program->update($request->all());
        return response()->json(['status' => 'success', 'message' => 'Program updated successfully']);
    }

    public function destroy($id)
    {
        Program::findOrFail($id)->delete();
        return response()->json(['status' => 'success', 'message' => 'Program deleted successfully']);
    }
}