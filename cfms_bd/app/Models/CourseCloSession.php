<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CourseCloSession extends Model
{
    use HasFactory;

    // Table ka naam explicitly define karna zaroori hai
    protected $table = 'course_clo_session';

    protected $fillable = [
        'course_id',
        'clo_id',
        'session_id',
    ];

    public function course()
    {
        return $this->belongsTo(Course::class);
    }

    public function clo()
    {
        return $this->belongsTo(Clo::class);
    }

    public function session()
    {
        return $this->belongsTo(Session::class);
    }
}