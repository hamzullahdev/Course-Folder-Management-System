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
        Schema::create('teachers', function (Blueprint $table) {
            $table->id();
            
            // Link to the Users table (The Identity)
            $table->foreignId('user_id')
                  ->constrained()
                  ->onDelete('cascade'); 

            // Link to Departments (The Profile)
            $table->foreignId('dept_id')
                  ->constrained('departments')
                  ->onDelete('restrict'); // Prevents deleting a dept if teachers are in it

            $table->string('teacher_name');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('teachers');
    }
};