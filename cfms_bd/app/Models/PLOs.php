<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PLOs extends Model
{
    // Agar aapka table ka naam 'plos' hai (jo migration mein tha), 
    // toh model ko explicitly batana parta hai jab class name capital ho:
    protected $table = 'plos'; 

    protected $fillable = ['plo_code', 'plo_description', 'program_id'];

    public function program()
    {
        return $this->belongsTo(Program::class, 'program_id');
    }
}