<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\TunnelController;
use Illuminate\Support\Facades\Route;

$webBasePath = trim((string) env('WEB_BASE_PATH', ''), '/');

if ($webBasePath !== '') {
    Route::prefix($webBasePath)->group(function () {
        Route::middleware('guest')->group(function () {
            Route::get('/login', [LoginController::class, 'create'])->name('login');
            Route::post('/login', [LoginController::class, 'store'])->middleware('throttle:6,1')->name('login.store');
        });

        Route::middleware('auth')->group(function () {
            Route::post('/logout', [LoginController::class, 'destroy'])->name('logout');
            Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
            Route::get('/tunnels', [TunnelController::class, 'index'])->name('tunnels.index');
            Route::get('/tunnels/create', [TunnelController::class, 'create'])->name('tunnels.create');
            Route::post('/tunnels', [TunnelController::class, 'store'])->name('tunnels.store');
        });
    });
}
