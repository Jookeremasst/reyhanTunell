@extends('layouts.app')

@section('title', 'تونل‌ها | reyhanTunell')
@section('page-title', 'تونل‌ها')

@section('content')
<div class="rt-page-heading">
    <div>
        <h1>مدیریت تونل‌ها</h1>
        <p>تونل‌های ایجادشده را مشاهده و کنترل کنید.</p>
    </div>
    <a class="rt-primary-button" href="{{ route('tunnels.create') }}">+ افزودن تونل</a>
</div>

@if (session('success'))
    <div class="rt-alert rt-alert-success">{{ session('success') }}</div>
@endif
@if (session('error'))
    <div class="rt-alert rt-alert-danger">{{ session('error') }}</div>
@endif

<section class="rt-tunnel-toolbar rt-card">
    <div class="rt-search-box">
        <span>⌕</span>
        <input type="search" id="tunnelSearch" placeholder="جستجوی تونل..." aria-label="جستجوی تونل">
    </div>
    <select class="rt-select" id="statusFilter" aria-label="فیلتر وضعیت">
        <option value="">همه وضعیت‌ها</option>
        <option value="active">فعال</option>
        <option value="inactive">متوقف</option>
        <option value="failed">خطا</option>
    </select>
    <button class="rt-secondary-button" type="button" onclick="window.location.reload()">↻ بروزرسانی</button>
</section>

<section class="rt-card rt-tunnels-card">
    <div class="rt-card-heading">
        <div>
            <h2>لیست تونل‌ها</h2>
            <span>مدیریت سرویس‌های reyhanTunell</span>
        </div>
        <span>{{ count($tunnels) }} تونل</span>
    </div>

    @if (count($tunnels) === 0)
        <div class="rt-empty-state">
            <div class="rt-empty-icon">⇄</div>
            <h3>هنوز تونلی ثبت نشده است</h3>
            <p>اولین تونل خود را ایجاد کنید تا از این بخش آن را مدیریت کنید.</p>
            <a class="rt-primary-button" href="{{ route('tunnels.create') }}">+ افزودن تونل</a>
        </div>
    @else
        <div class="rt-table-wrap">
            <table class="rt-table rt-tunnel-table">
                <thead>
                    <tr>
                        <th>شناسه</th>
                        <th>نوع</th>
                        <th>محلی</th>
                        <th>مقصد</th>
                        <th>وضعیت</th>
                        <th>عملیات</th>
                    </tr>
                </thead>
                <tbody id="tunnelRows">
                    @foreach ($tunnels as $tunnel)
                    @php
                        $status = strtolower($tunnel['status'] ?? 'unknown');
                        $statusClass = in_array($status, ['active', 'running']) ? 'is-online' : ($status === 'failed' ? 'is-offline' : 'is-muted');
                    @endphp
                    <tr data-search="{{ strtolower(($tunnel['id'] ?? '') . ' ' . ($tunnel['type'] ?? '') . ' ' . ($tunnel['remote_host'] ?? '')) }}" data-status="{{ in_array($status, ['active', 'running']) ? 'active' : ($status === 'failed' ? 'failed' : 'inactive') }}">
                        <td><strong>{{ $tunnel['id'] ?? '-' }}</strong></td>
                        <td>{{ strtoupper($tunnel['type'] ?? '-') }}</td>
                        <td>{{ ($tunnel['local_address'] ?? '-') }}:{{ $tunnel['local_port'] ?? '-' }}</td>
                        <td>{{ ($tunnel['remote_host'] ?? '-') }}:{{ $tunnel['remote_port'] ?? '-' }}</td>
                        <td><span class="rt-status {{ $statusClass }}">{{ $tunnel['status'] ?? 'نامشخص' }}</span></td>
                        <td class="rt-actions">
                            <button class="rt-action-button" type="button">شروع</button>
                            <button class="rt-action-button" type="button">توقف</button>
                            <button class="rt-action-button" type="button">ری‌استارت</button>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @endif
</section>
@endsection

@push('scripts')
<script>
(() => {
    const search = document.getElementById('tunnelSearch');
    const filter = document.getElementById('statusFilter');
    const rows = () => document.querySelectorAll('#tunnelRows tr');

    function applyFilter() {
        const q = (search?.value || '').trim().toLowerCase();
        const status = filter?.value || '';
        rows().forEach(row => {
            const matchesText = !q || row.dataset.search.includes(q);
            const matchesStatus = !status || row.dataset.status === status;
            row.style.display = matchesText && matchesStatus ? '' : 'none';
        });
    }

    search?.addEventListener('input', applyFilter);
    filter?.addEventListener('change', applyFilter);
})();
</script>
@endpush
