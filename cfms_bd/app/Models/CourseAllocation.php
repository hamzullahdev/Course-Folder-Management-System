<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CourseAllocation extends Model
{
    use HasFactory;

    protected $table = 'course_allocations';

    protected $fillable = [
        'teacher_id',
        'course_offered_id',
        'session_id',
        'batch_id',
        'section',
        'status',
        'reason',
    ];

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class, 'teacher_id');
    }

    public function courseOffered(): BelongsTo
    {
        return $this->belongsTo(CourseOffered::class, 'course_offered_id');
    }

    public function session(): BelongsTo
    {
        return $this->belongsTo(Session::class, 'session_id');
    }

    public function batch(): BelongsTo
    {
        return $this->belongsTo(Batch::class, 'batch_id');
    }

    public function fileSubmissions()
    {
        return $this->hasMany(\App\Models\Teacher\FileSubmission::class, 'course_allocation_id', 'id');
    }
}