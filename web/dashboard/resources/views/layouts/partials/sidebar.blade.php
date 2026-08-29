<aside class="rt-sidebar">
    <div class="rt-brand">
        <div class="rt-brand-mark">RT</div>
        <div>
            <div class="rt-brand-name">reyhanTunell</div>
            <div class="rt-brand-subtitle">Tunnel Manager</div>
        </div>
    </div>

    <nav class="rt-nav" aria-label="منوی اصلی">
        <a class="rt-nav-item {{ request()->routeIs('dashboard') ? 'is-active' : '' }}" href="{{ route('dashboard') }}">
            <span class="rt-nav-icon">⌂</span><span>داشبورد</span>
        </a>
        <a class="rt-nav-item {{ request()->routeIs('tunnels.*') ? 'is-active' : '' }}" href="{{ route('tunnels.index') }}">
            <span class="rt-nav-icon">⇄</span><span>تونل‌ها</span>
        </a>
        <a class="rt-nav-item" href="#"><span class="rt-nav-icon">▣</span><span>سرورها</span></a>
        <a class="rt-nav-item" href="#"><span class="rt-nav-icon">◇</span><span>پرووایدرها</span></a>
        <a class="rt-nav-item" href="#"><span class="rt-nav-icon">≡</span><span>لاگ‌ها</span></a>
        <a class="rt-nav-item" href="#"><span class="rt-nav-icon">⚙</span><span>تنظیمات</span></a>
    </nav>

    <div class="rt-sidebar-bottom">
        <div class="rt-sidebar-version">reyhanTunell v0.1.0</div>
    </div>
</aside>
