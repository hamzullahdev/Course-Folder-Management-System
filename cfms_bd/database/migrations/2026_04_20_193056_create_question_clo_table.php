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
        Schema::create('question_clo', function (Blueprint $table) {

    $table->id(); // Primary Key

    // FK → Question
    $table->foreignId('question_id')
          ->constrained()
          ->cascadeOnDelete();

    // FK → CLO
    $table->foreignId('clo_id')
          ->constrained()
          ->cascadeOnDelete();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('question_clo');
    }
};
