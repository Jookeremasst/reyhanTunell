<!doctype html>
<html lang="en" dir="ltr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Web Dashboard - Sign in</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="min-h-screen">
    <main class="min-h-screen flex items-center justify-center p-6">
        <section class="w-full max-w-md rounded-2xl border border-white/10 bg-slate-900/90 p-8 shadow-2xl">
            <div class="mb-8 text-center">
                <h1 class="text-2xl font-bold">Web Dashboard</h1>
                <p class="mt-2 text-sm text-slate-400">Sign in to manage reyhanTunell.</p>
            </div>

            @if ($errors->any())
                <div class="mb-5 rounded-lg border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-300">
                    {{ $errors->first() }}
                </div>
            @endif

            <form method="POST" action="{{ route('login.store') }}" class="space-y-5">
                @csrf
                <div>
                    <label for="username" class="mb-2 block text-sm font-medium">Username</label>
                    <input id="username" name="username" type="text" value="{{ old('username') }}" required autofocus autocomplete="username"
                           class="w-full rounded-lg border border-white/10 bg-slate-800 px-4 py-3 outline-none focus:border-indigo-400">
                </div>

                <div>
                    <label for="password" class="mb-2 block text-sm font-medium">Password</label>
                    <input id="password" name="password" type="password" required autocomplete="current-password"
                           class="w-full rounded-lg border border-white/10 bg-slate-800 px-4 py-3 outline-none focus:border-indigo-400">
                </div>

                <label class="flex items-center gap-2 text-sm text-slate-400">
                    <input type="checkbox" name="remember" value="1" class="rounded">
                    Remember me
                </label>

                <button type="submit" class="w-full rounded-lg bg-indigo-600 px-4 py-3 font-semibold transition hover:bg-indigo-500">
                    Sign in
                </button>
            </form>
        </section>
    </main>
</body>
</html>
