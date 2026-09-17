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
       Schema::create('clo_plo', function (Blueprint $table) {
    $table->id();

    $table->foreignId('clo_id')->constrained()->cascadeOnDelete();
    $table->foreignId('plo_id')->constrained()->cascadeOnDelete();
});
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clo_plo');
    }
};
