<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash; 

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create Default Teacher Account
        User::create([
            'email' => 'teacher@gmail.com',
            'password' => Hash::make('teacher123'), 
            'role' => 'teacher',
        ]);

        // 2. Create Default Admin Account
        User::create([
            'email' => 'admin@gmail.com',
            'password' => Hash::make('admin123'), 
            'role' => 'admin',
        ]);
    }
}