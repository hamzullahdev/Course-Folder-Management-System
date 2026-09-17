<?php

namespace App\Models\Teacher;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Student;

class Result extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'question_id',
        'obtained_marks'
    ];

    public function student()
    {
        return $this->belongsTo(Student::class, 'student_id');
    }

    public function question()
    {
        return $this->belongsTo(Question::class, 'question_id');
    }
}