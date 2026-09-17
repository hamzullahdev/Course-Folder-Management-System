<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CourseOffered extends Model
{
    // Table ka naam set karna zaroori hai
    protected $table = 'course_offered';

    // Mass assignment ke liye fillable fields
    protected $fillable = [
        'course_id',
        'session_id',
    ];

    /**
     * Relationship: Ek offered course ka ek specific Course record hota hai.
     */
    public function course(): BelongsTo
    {
        return $this->belongsTo(Course::class, 'course_id');
    }

    /**
     * Relationship: Ek offered course ka ek specific Session record hota hai.
     */
    public function session(): BelongsTo
    {
        return $this->belongsTo(Session::class, 'session_id');
    }
}