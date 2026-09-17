<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Teacher extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'dept_id',
        'teacher_name'
    ];

    /**
     * Get the User account identity associated with the teacher.
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Get the Department record assigned to the teacher.
     */
    public function department()
    {
        return $this->belongsTo(Department::class, 'dept_id');
    }
}