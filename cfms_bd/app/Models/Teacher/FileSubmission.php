<?php

namespace App\Models\Teacher;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FileSubmission extends Model
{
    use HasFactory;

    protected $table = 'file_submissions';
    
    // Disabling default timestamps since we only use 'uploaded_at'
    public $timestamps = false; 

    protected $fillable = [
        'file_id',
        'course_allocation_id',
        'file_path',
        'uploaded_at'
    ];

    public function file()
    {
        return $this->belongsTo(\App\Models\File::class, 'file_id', 'file_id');
    }

    public function courseAllocation()
    {
        return $this->belongsTo(CourseAllocation::class, 'course_allocation_id');
    }
}