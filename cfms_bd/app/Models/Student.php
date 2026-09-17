<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $table = 'students';

    protected $fillable = [
        'std_name',
        'reg_no',
        'program_id',
        'batch_id',
        'user_id', // ✨ FIX: Excel import ke waqt user link karne ke liye lazmi hai
    ];

    public function program()
    {
        return $this->belongsTo(Program::class);
    }

    public function batch()
    {
        return $this->belongsTo(Batch::class);
    }

    public function enrollments()
    {
        return $this->hasMany(Enrollment::class, 'student_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }
}