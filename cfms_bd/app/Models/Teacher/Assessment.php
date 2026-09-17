<?php

namespace App\Models\Teacher;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Assessment extends Model
{
    use HasFactory;

    protected $fillable = ['course_allocation_id', 'type', 'weightage'];

    public function courseAllocation()
    {
        return $this->belongsTo(\App\Models\CourseAllocation::class, 'course_allocation_id');
    }
}