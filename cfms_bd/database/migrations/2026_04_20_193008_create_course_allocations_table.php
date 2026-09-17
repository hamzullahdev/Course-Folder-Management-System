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
        Schema::create('course_allocations', function (Blueprint $table) {
    $table->id();

    $table->foreignId('teacher_id')->constrained()->cascadeOnDelete();
    $table->foreignId('course_offered_id')->constrained('course_offered')->cascadeOnDelete();
    $table->foreignId('session_id')->constrained()->cascadeOnDelete();
    $table->foreignId('batch_id')->constrained()->cascadeOnDelete();

    $table->string('section');
    $table->string('status');
    $table->string('reason');


    $table->timestamps();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('course_allocations');
    }
};
