<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    use HasFactory;

    protected $fillable = [
        'course_name',
        'course_code',
        'short_name',
        'credit_hrs',
        'program_id',
    ];

    public function program()
    {
        return $this->belongsTo(Program::class, 'program_id');
    }
}