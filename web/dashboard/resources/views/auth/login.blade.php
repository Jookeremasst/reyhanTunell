<!doctype html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="dark">
    <title>ورود به پنل ریحان تانل</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html, body { min-height: 100%; }
        body {
            min-height: 100vh;
            overflow: hidden;
            background: #080710;
            color: #fff;
            font-family: Tahoma, Arial, sans-serif;
        }
        .background {
            position: fixed;
            width: 430px;
            height: 520px;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            pointer-events: none;
        }
        .shape {
            position: absolute;
            width: 200px;
            height: 200px;
            border-radius: 50%;
        }
        .shape:first-child {
            left: -80px;
            top: -80px;
            background: linear-gradient(#1845ad, #23a2f6);
        }
        .shape:last-child {
            right: -30px;
            bottom: -80px;
            background: linear-gradient(to right, #ff512f, #f09819);
        }
        .login-card {
            position: fixed;
            width: min(400px, calc(100vw - 32px));
            min-height: 500px;
            left: 50%;
            top: 50%;
            transform: translate(-50%, -50%);
            padding: 42px 35px;
            border: 2px solid rgba(255,255,255,.10);
            border-radius: 16px;
            background: rgba(255,255,255,.13);
            box-shadow: 0 0 40px rgba(8,7,16,.60);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
        }
        .brand {
            text-align: center;
            margin-bottom: 30px;
        }
        .brand h1 {
            font-size: 29px;
            font-weight: 700;
            line-height: 1.5;
        }
        .brand p {
            margin-top: 7px;
            color: #d7d7df;
            font-size: 13px;
        }
        .field { margin-top: 22px; }
        label {
            display: block;
            margin-bottom: 8px;
            font-size: 14px;
            font-weight: 600;
        }
        input {
            display: block;
            width: 100%;
            height: 50px;
            padding: 0 14px;
            border: 1px solid rgba(255,255,255,.12);
            border-radius: 6px;
            outline: none;
            background: rgba(255,255,255,.07);
            color: #fff;
            font-size: 14px;
            direction: ltr;
            text-align: left;
            transition: border-color .2s, background .2s;
        }
        input::placeholder { color: #d9d9df; }
        input:focus {
            border-color: rgba(35,162,246,.8);
            background: rgba(255,255,255,.10);
        }
        .remember {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: 17px;
            color: #dddde5;
            font-size: 13px;
            cursor: pointer;
        }
        .remember input {
            width: 16px;
            height: 16px;
            margin: 0;
            accent-color: #23a2f6;
        }
        .error {
            margin-bottom: 18px;
            padding: 11px 13px;
            border: 1px solid rgba(255,81,47,.35);
            border-radius: 7px;
            background: rgba(255,81,47,.12);
            color: #ffd8d0;
            font-size: 13px;
            line-height: 1.8;
        }
        button {
            width: 100%;
            height: 52px;
            margin-top: 27px;
            border: 0;
            border-radius: 6px;
            background: #fff;
            color: #080710;
            font-size: 17px;
            font-weight: 700;
            cursor: pointer;
            transition: transform .15s, opacity .15s;
        }
        button:hover { opacity: .92; }
        button:active { transform: scale(.99); }
        .footer-note {
            margin-top: 22px;
            text-align: center;
            color: rgba(255,255,255,.58);
            font-size: 11px;
        }
        @media (max-width: 520px) {
            .background { transform: translate(-50%, -50%) scale(.78); }
            .login-card { padding: 34px 24px; min-height: 0; }
            .brand h1 { font-size: 25px; }
        }
    </style>
</head>
<body>
    <div class="background" aria-hidden="true">
        <div class="shape"></div>
        <div class="shape"></div>
    </div>

    <main class="login-card" aria-labelledby="login-title">
        <div class="brand">
            <h1 id="login-title">ورود به پنل ریحان تانل</h1>
            <p>برای مدیریت سرویس وارد حساب خود شوید</p>
        </div>

        @if ($errors->any())
            <div class="error" role="alert">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="{{ route('login.store') }}">
            @csrf

            <div class="field">
                <label for="username">نام کاربری</label>
                <input id="username" name="username" type="text"
                       value="{{ old('username') }}"
                       placeholder="نام کاربری را وارد کنید"
                       required autofocus autocomplete="username">
            </div>

            <div class="field">
                <label for="password">رمز عبور</label>
                <input id="password" name="password" type="password"
                       placeholder="رمز عبور را وارد کنید"
                       required autocomplete="current-password">
            </div>

            <label class="remember">
                <input type="checkbox" name="remember" value="1">
                <span>مرا به خاطر بسپار</span>
            </label>

            <button type="submit">ورود به پنل</button>
        </form>

        <div class="footer-note">reyhanTunell Web Dashboard</div>
    </main>
</body>
</html>
