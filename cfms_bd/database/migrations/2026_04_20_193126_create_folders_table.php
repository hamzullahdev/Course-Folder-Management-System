<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations to establish the folders schema table.
     */
    public function up(): void
    {
        Schema::create('folders', function (Blueprint $table) {
            // Primary key using naming convention explicitly specified in ERD
            $table->id('folder_id'); 
            
            // Stores unique folder names to guarantee structural validation checks at database tier
            $table->string('folder_name')->unique(); 
            
            // Total explicit files allowed. Initialized to 0 if folder houses subfolders
            $table->integer('no_of_files')->default(0); 
            
            // Self-referencing structural foreign key allowing hierarchical folder tracking layouts
            // Nullable because root level folder elements do not contain parent pointers
            $table->unsignedBigInteger('parent_id')->nullable();
            
            $table->timestamps();

            // Establish the self-referencing integrity constraint matrix line links
            $table->foreign('parent_id')
                  ->references('folder_id')
                  ->on('folders')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('folders');
    }
};