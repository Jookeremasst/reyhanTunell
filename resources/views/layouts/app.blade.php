<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'reyhanTunell')</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @stack('styles')
</head>
<body class="rt-body">
    <div class="rt-shell">
        @include('layouts.partials.sidebar')

        <div class="rt-main">
            @include('layouts.partials.header')

            <main class="rt-content">
                @yield('content')
            </main>

            @include('layouts.partials.footer')
        </div>
    </div>
    @stack('scripts')
</body>
</html>
