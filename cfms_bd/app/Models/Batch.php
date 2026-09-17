<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Batch extends Model
{
    use HasFactory;

    // The attributes that are mass assignable
    protected $fillable = [
        'batch_name',
        'program_id',
    ];

    /**
     * Relationship: A Batch belongs to a Program.
     */
    public function program()
    {
        return $this->belongsTo(Program::class, 'program_id');
    }
}