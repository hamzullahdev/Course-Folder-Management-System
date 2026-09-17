<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Clo extends Model
{
    use HasFactory;

    protected $fillable = [
        'clos_code',
        'clos_description',
        'course_id',
    ];

    public function course()
    {
        return $this->belongsTo(Course::class);
    }
}