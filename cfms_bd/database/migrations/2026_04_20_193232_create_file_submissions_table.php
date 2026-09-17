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
        Schema::create('file_submissions', function (Blueprint $table) {

    $table->id(); // PK

    // Which expected file this is
    $table->foreignId('file_id')
          ->constrained('files','file_id')
          ->cascadeOnDelete();

    // Who uploaded it (Teacher)
    $table->foreignId('course_allocation_id')
          ->constrained('course_allocations')
          ->cascadeOnDelete();

    // Actual uploaded file path
    $table->string('file_path');


    // Upload time
    $table->timestamp('uploaded_at')->useCurrent();

});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('file_submissions');
    }
};
