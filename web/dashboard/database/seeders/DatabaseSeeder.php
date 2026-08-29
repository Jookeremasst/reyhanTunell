<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use RuntimeException;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $username = env('DASHBOARD_ADMIN_USERNAME');
        $password = env('DASHBOARD_ADMIN_PASSWORD');

        if (! $username || ! $password) {
            throw new RuntimeException('DASHBOARD_ADMIN_USERNAME and DASHBOARD_ADMIN_PASSWORD must be set before seeding the dashboard administrator.');
        }

        User::updateOrCreate(
            ['username' => $username],
            [
                'name' => env('DASHBOARD_ADMIN_NAME', 'Administrator'),
                'email' => env('DASHBOARD_ADMIN_EMAIL'),
                'password' => $password,
            ]
        );
    }
}
