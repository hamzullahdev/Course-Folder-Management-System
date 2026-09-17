<?php

namespace App\Models\Teacher;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Clo;

class Question extends Model
{
    use HasFactory;

    protected $fillable = [
        'assessment_id', 
        'question_text', 
        'total_marks'
    ];

    // Relationship with Assessment
    public function assessment()
    {
        return $this->belongsTo(\App\Models\Teacher\Assessment::class, 'assessment_id');
    }

    // Many-to-Many Relationship with CLOs via 'question_clo' pivot table
    public function clos()
    {
        return $this->belongsToMany(Clo::class, 'question_clo', 'question_id', 'clo_id');
    }
}