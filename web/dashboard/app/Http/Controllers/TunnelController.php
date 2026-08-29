<?php

namespace App\Http\Controllers;

use Illuminate\View\View;

class TunnelController extends Controller
{
    public function index(): View
    {
        return view('tunnels.index', [
            'tunnels' => [],
        ]);
    }
}
