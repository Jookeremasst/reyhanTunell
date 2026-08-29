<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('dashboard.index', [
            'stats' => [
                ['label' => 'کل تونل‌ها', 'value' => 12, 'icon' => 'tunnel'],
                ['label' => 'فعال', 'value' => 8, 'icon' => 'activity'],
                ['label' => 'سرورها', 'value' => 4, 'icon' => 'server'],
                ['label' => 'خطاها', 'value' => 1, 'icon' => 'alert'],
            ],
            'activities' => [
                'تونل DE-01 با موفقیت راه‌اندازی شد.',
                'اتصال سرور خارجی بررسی شد.',
                'OpenVPN Tunnel به‌روزرسانی شد.',
                'لاگ سرویس‌ها بررسی شد.',
            ],
            'tunnels' => [
                ['name' => 'DE-01', 'protocol' => 'OpenVPN', 'status' => 'فعال'],
                ['name' => 'DE-02', 'protocol' => 'WireGuard', 'status' => 'فعال'],
                ['name' => 'TR-01', 'protocol' => 'SSH', 'status' => 'متوقف'],
            ],
            'health' => [
                ['label' => 'CPU', 'value' => '24%'],
                ['label' => 'RAM', 'value' => '41%'],
                ['label' => 'Network', 'value' => '128 Mbps'],
                ['label' => 'Uptime', 'value' => '7d 14h'],
            ],
        ]);
    }
}
