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
    Schema::create('batches', function (Blueprint $table) {
        $table->id();
        $table->string('batch_name'); // e.g., 2025-2029
        $table->foreignId('program_id')->constrained()->cascadeOnDelete();
        $table->timestamps();

        // Prevent duplicate batches for the same program (e.g., can't have two "2025-2029" in BSCS)
        $table->unique(['batch_name', 'program_id']);
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('batches');
    }
};
