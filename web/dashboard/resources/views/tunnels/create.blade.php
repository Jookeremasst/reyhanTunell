@extends('layouts.app')

@section('title', 'افزودن تونل | reyhanTunell')
@section('page-title', 'افزودن تونل')

@section('content')
<div class="rt-page-heading">
    <div>
        <h1>افزودن تونل</h1>
        <p>یک تونل جدید برای reyhanTunell ایجاد کنید.</p>
    </div>
    <a class="rt-secondary-button" href="{{ route('tunnels.index') }}">← بازگشت</a>
</div>

@if ($errors->any())
    <div class="rt-alert rt-alert-danger">
        <strong>اطلاعات کامل نیست.</strong>
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

@if (session('error'))
    <div class="rt-alert rt-alert-danger">{{ session('error') }}</div>
@endif

<section class="rt-card rt-form-card">
    <form method="POST" action="{{ route('tunnels.store') }}" id="tunnelForm">
        @csrf

        <div class="rt-form-section">
            <div class="rt-form-section-title">
                <h2>اطلاعات اصلی</h2>
                <span>نوع تونل را انتخاب کنید.</span>
            </div>

            <div class="rt-form-grid">
                <div class="rt-field">
                    <label for="id">شناسه تونل</label>
                    <input id="id" name="id" value="{{ old('id') }}" required maxlength="120" placeholder="مثلاً germany-ssh-01">
                    <small>این شناسه برای سرویس سیستم نیز استفاده می‌شود.</small>
                </div>

                <div class="rt-field">
                    <label for="type">نوع تونل</label>
                    <select id="type" name="type" required class="rt-select rt-field-control">
                        <option value="ssh" @selected(old('type', 'ssh') === 'ssh')>SSH</option>
                        <option value="socks5" @selected(old('type') === 'socks5')>SOCKS5</option>
                    </select>
                </div>
            </div>
        </div>

        <div class="rt-form-section">
            <div class="rt-form-section-title">
                <h2>مسیر تونل</h2>
                <span>مبدأ و مقصد اتصال را مشخص کنید.</span>
            </div>

            <div class="rt-form-grid">
                <div class="rt-field">
                    <label for="local_address">آدرس محلی</label>
                    <input id="local_address" name="local_address" value="{{ old('local_address', '127.0.0.1') }}" required placeholder="127.0.0.1">
                </div>
                <div class="rt-field">
                    <label for="local_port">پورت محلی</label>
                    <input id="local_port" name="local_port" type="number" min="1" max="65535" value="{{ old('local_port') }}" required placeholder="8080">
                </div>
                <div class="rt-field">
                    <label for="remote_host">سرور مقصد</label>
                    <input id="remote_host" name="remote_host" value="{{ old('remote_host') }}" required placeholder="server.example.com یا IP">
                </div>
                <div class="rt-field">
                    <label for="remote_port">پورت مقصد</label>
                    <input id="remote_port" name="remote_port" type="number" min="1" max="65535" value="{{ old('remote_port') }}" required placeholder="443">
                </div>
            </div>
        </div>

        <div class="rt-form-section" id="sshFields">
            <div class="rt-form-section-title">
                <h2>تنظیمات SSH</h2>
                <span>اطلاعات ورود به سرور SSH.</span>
            </div>
            <div class="rt-form-grid">
                <div class="rt-field">
                    <label for="user">کاربر SSH</label>
                    <input id="user" name="user" value="{{ old('user') }}" placeholder="root">
                </div>
                <div class="rt-field">
                    <label for="host">آدرس سرور SSH</label>
                    <input id="host" name="host" value="{{ old('host') }}" placeholder="server.example.com یا IP">
                </div>
                <div class="rt-field">
                    <label for="ssh_port">پورت SSH</label>
                    <input id="ssh_port" name="ssh_port" type="number" min="1" max="65535" value="{{ old('ssh_port', 22) }}">
                </div>
                <div class="rt-field rt-field-wide">
                    <label for="key_path">مسیر کلید خصوصی</label>
                    <input id="key_path" name="key_path" value="{{ old('key_path') }}" placeholder="/root/.ssh/id_ed25519">
                </div>
            </div>
        </div>

        <div class="rt-form-section" id="socks5Fields" hidden>
            <div class="rt-form-section-title">
                <h2>تنظیمات SOCKS5</h2>
                <span>در صورت نیاز، احراز هویت SOCKS5 را وارد کنید.</span>
            </div>
            <div class="rt-form-grid">
                <div class="rt-field">
                    <label for="socks5_user">نام کاربری SOCKS5</label>
                    <input id="socks5_user" name="socks5_user" value="{{ old('socks5_user') }}">
                </div>
                <div class="rt-field">
                    <label for="socks5_pass">رمز SOCKS5</label>
                    <input id="socks5_pass" name="socks5_pass" type="password" value="{{ old('socks5_pass') }}">
                </div>
            </div>
        </div>

        <div class="rt-form-actions">
            <a class="rt-secondary-button" href="{{ route('tunnels.index') }}">انصراف</a>
            <button class="rt-primary-button" type="submit">+ ایجاد تونل</button>
        </div>
    </form>
</section>
@endsection

@push('scripts')
<script>
(function () {
    const type = document.getElementById('type');
    const ssh = document.getElementById('sshFields');
    const socks5 = document.getElementById('socks5Fields');
    const sshInputs = ssh.querySelectorAll('input');

    function updateFields() {
        const isSsh = type.value === 'ssh';
        ssh.hidden = !isSsh;
        socks5.hidden = isSsh;
        sshInputs.forEach(input => input.disabled = !isSsh);
    }

    type.addEventListener('change', updateFields);
    updateFields();
})();
</script>
@endpush
