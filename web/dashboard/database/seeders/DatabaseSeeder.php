<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use RuntimeException;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $email = env('DASHBOARD_ADMIN_EMAIL');
        $password = env('DASHBOARD_ADMIN_PASSWORD');

        if (! $email || ! $password) {
            throw new RuntimeException('DASHBOARD_ADMIN_EMAIL and DASHBOARD_ADMIN_PASSWORD must be set before seeding the dashboard administrator.');
        }

        User::updateOrCreate(
            ['email' => $email],
            [
                'name' => env('DASHBOARD_ADMIN_NAME', 'Administrator'),
                'password' => $password,
            ]
        );
    }
}
