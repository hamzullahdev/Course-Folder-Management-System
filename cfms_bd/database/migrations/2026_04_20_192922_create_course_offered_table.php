<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
       Schema::create('course_offered', function (Blueprint $table) {
       $table->id();
       // The Core Connection
       $table->foreignId('course_id')->constrained('courses')->onDelete('cascade');
       $table->foreignId('session_id')->constrained('sessions')->onDelete('cascade');
    
       $table->timestamps();
    
       // Prevent duplicate offerings (Same course in same session)
       $table->unique(['course_id', 'session_id']); 
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('course_offered');
    }
};
