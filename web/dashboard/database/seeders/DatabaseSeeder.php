<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => env('DASHBOARD_ADMIN_EMAIL', 'admin@example.com')],
            [
                'name' => env('DASHBOARD_ADMIN_NAME', 'Administrator'),
                'password' => env('DASHBOARD_ADMIN_PASSWORD', 'ChangeThisPassword123!'),
            ]
        );
    }
}
