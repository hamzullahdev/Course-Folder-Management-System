<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Enrollment extends Model
{
    protected $table = 'enrollments';

    protected $fillable = [
        'student_id',
        'section',
        'course_offered_id',
    ];

    /**
     * Relationship: An enrollment belongs to a specific student record.
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class, 'student_id');
    }

    /**
     * Relationship: An enrollment maps directly to a valid session's course offering.
     */
    public function courseOffered(): BelongsTo
    {
        return $this->belongsTo(CourseOffered::class, 'course_offered_id');
    }
}