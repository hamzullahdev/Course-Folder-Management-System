<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class File extends Model
{
    use HasFactory;

    // Explicitly defining the primary key as per your ERD
    protected $primaryKey = 'file_id';

    protected $fillable = [
        'file_name',
        'folder_id',
    ];

    /**
     * Relationship: A file belongs to a single folder.
     */
    public function folder()
    {
        return $this->belongsTo(Folder::class, 'folder_id', 'folder_id');
    }
}