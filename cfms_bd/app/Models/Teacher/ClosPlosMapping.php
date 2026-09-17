<?php

namespace App\Models\Teacher;

use Illuminate\Database\Eloquent\Model;

class ClosPlosMapping extends Model
{
    // Mapping to the pivot table
    protected $table = 'clo_plo';
    
    // Disable timestamps if not present in migration
    public $timestamps = false;

    protected $fillable = [
        'clo_id',
        'plo_id'
    ];
}