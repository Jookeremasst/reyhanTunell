<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\View\View;

class TunnelController extends Controller
{
    public function index(): View|RedirectResponse
    {
        $response = $this->api()->get('/api/v1/tunnels');

        if ($response->failed()) {
            return redirect()->route('dashboard')->with('error', 'دریافت لیست تونل‌ها انجام نشد.');
        }

        $tunnels = $response->json('data', []);

        return view('tunnels.index', compact('tunnels'));
    }

    public function create(): View
    {
        return view('tunnels.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $type = strtolower((string) $request->input('type'));

        $rules = [
            'id' => ['required', 'string', 'max:120', 'regex:/^[^\\\/]+$/'],
            'type' => ['required', 'in:ssh,socks5'],
            'local_address' => ['required', 'ip'],
            'local_port' => ['required', 'integer', 'between:1,65535'],
            'remote_host' => ['required', 'string', 'max:255'],
            'remote_port' => ['required', 'integer', 'between:1,65535'],
        ];

        if ($type === 'ssh') {
            $rules += [
                'user' => ['required', 'string', 'max:120'],
                'host' => ['required', 'string', 'max:255'],
                'ssh_port' => ['required', 'integer', 'between:1,65535'],
                'key_path' => ['required', 'string', 'max:500'],
            ];
        }

        if ($type === 'socks5') {
            $rules += [
                'socks5_user' => ['nullable', 'string', 'max:120'],
                'socks5_pass' => ['nullable', 'string', 'max:255'],
            ];
        }

        $data = $request->validate($rules);
        $data['status'] = 'configured';

        $response = $this->api()->post('/api/v1/tunnels', $data);

        if ($response->failed()) {
            $message = $response->json('error', 'ایجاد تونل انجام نشد.');
            return back()->withInput()->with('error', $message);
        }

        return redirect()->route('tunnels.index')->with('success', 'تونل با موفقیت ایجاد شد.');
    }

    private function api()
    {
        $token = env('REYHAN_API_TOKEN');

        if (!$token && is_readable('/etc/reyhanTunell/api.token')) {
            $token = trim((string) file_get_contents('/etc/reyhanTunell/api.token'));
        }

        return Http::baseUrl('http://127.0.0.1:8765')
            ->withToken($token ?? '')
            ->acceptJson()
            ->timeout(10);
    }
}
