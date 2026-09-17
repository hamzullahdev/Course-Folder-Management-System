<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Department;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DepartmentController extends Controller
{
    public function index()
    {
        // Data sequence mein lane ke liye 'orderBy' ka use kiya gaya hai
        $departments = Department::orderBy('id', 'asc')->get();
        return response()->json(['status' => 'success', 'data' => $departments]);
    }

    public function store(Request $request)
    {
        // Unique validation: dept_name table mein unique hona chahiye
        $request->validate([
            'dept_name' => 'required|string|max:255|unique:departments,dept_name'
        ]);

        $department = Department::create($request->all());
        return response()->json([
            'status' => 'success', 
            'message' => 'Department created successfully', 
            'data' => $department
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $department = Department::findOrFail($id);
        
        // Unique validation: update karte waqt current id ko ignore karna zaroori hai
        $request->validate([
            'dept_name' => [
                'required', 
                'string', 
                'max:255', 
                Rule::unique('departments', 'dept_name')->ignore($id)
            ]
        ]);

        $department->update($request->all());
        return response()->json(['status' => 'success', 'message' => 'Department updated successfully']);
    }

    public function destroy($id)
    {
        $department = Department::findOrFail($id);
        $department->delete();
        return response()->json(['status' => 'success', 'message' => 'Department deleted successfully']);
    }
}