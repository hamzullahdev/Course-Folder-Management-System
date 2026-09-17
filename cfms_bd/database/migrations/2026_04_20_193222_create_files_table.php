<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // Build the files table in the database
    public function up(): void
    {
        Schema::create('files', function (Blueprint $table) {
            // Primary key using the exact name from your ERD
            $table->id('file_id'); 
            
            // Name of the file given by the Admin
            $table->string('file_name'); 
            
            // Foreign key to link this file to its folder
            $table->unsignedBigInteger('folder_id'); 
            
            $table->timestamps();

            // Set up the relationship: if a folder is deleted, delete its files too
            $table->foreign('folder_id')
                  ->references('folder_id')
                  ->on('folders')
                  ->onDelete('cascade');
        });
    }

    // Drop the table if we roll back migrations
    public function down(): void
    {
        Schema::dropIfExists('files');
    }
};