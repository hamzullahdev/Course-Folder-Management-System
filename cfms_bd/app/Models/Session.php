<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Carbon\Carbon;

class Session extends Model
{
    use HasFactory;

    // Explicitly definition to prevent system conflicts with Laravel default session driver
    protected $table = 'sessions';

    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        's_name',
        'start_date',
        'end_date',
    ];

    /**
     * Accessor & Mutator for Start Date
     * API ko dd/mm/yyyy dega aur Database mein yyyy-mm-dd save karega
     */
    protected function startDate(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => Carbon::parse($value)->format('d/m/Y'),
            set: fn ($value) => Carbon::createFromFormat('d/m/Y', $value)->format('Y-m-d'),
        );
    }

    /**
     * Accessor & Mutator for End Date
     * API ko dd/mm/yyyy dega aur Database mein yyyy-mm-dd save karega
     */
    protected function endDate(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => Carbon::parse($value)->format('d/m/Y'),
            set: fn ($value) => Carbon::createFromFormat('d/m/Y', $value)->format('Y-m-d'),
        );
    }
}