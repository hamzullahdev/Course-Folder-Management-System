<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Folder extends Model
{
    use HasFactory;

    // Explicitly defining the primary key since it is not 'id'
    protected $primaryKey = 'folder_id';

    protected $fillable = [
        'folder_name',
        'no_of_files',
        'parent_id',
    ];

    /**
     * Relationship: Get the parent folder of this folder.
     */
    public function parent()
    {
        return $this->belongsTo(Folder::class, 'parent_id', 'folder_id');
    }

    /**
     * Relationship: Get the subfolders (children) inside this folder.
     */
    public function subfolders()
    {
        return $this->hasMany(Folder::class, 'parent_id', 'folder_id');
    }
}