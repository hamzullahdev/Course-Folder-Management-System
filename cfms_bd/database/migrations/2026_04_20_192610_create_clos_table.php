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
        Schema::create('clos', function (Blueprint $table) {
        $table->id();
        $table->string('clos_code'); 
        $table->text('clos_description');
        $table->foreignId('course_id')->constrained()->cascadeOnDelete();
        // Ensure a course cannot have two "CLO_1"s
        $table->unique(['clos_code', 'course_id']); 
        $table->timestamps();
    });
}

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clos');
    }
};
