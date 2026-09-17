<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Program extends Model
{
    protected $fillable = ['program_name', 'department_id'];

    public function department()
    {
        return $this->belongsTo(Department::class);
    }
}