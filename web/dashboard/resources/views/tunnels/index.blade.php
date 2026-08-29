@extends('layouts.app')

@section('title', 'تونل‌ها | reyhanTunell')
@section('page-title', 'تونل‌ها')

@section('content')
<div class="rt-page-heading">
    <div>
        <h1>مدیریت تونل‌ها</h1>
        <p>تونل‌های ایجادشده را مشاهده و کنترل کنید.</p>
    </div>
    <button class="rt-primary-button" type="button">+ افزودن تونل</button>
</div>

<section class="rt-tunnel-toolbar rt-card">
    <div class="rt-search-box">
        <span>⌕</span>
        <input type="search" placeholder="جستجوی تونل..." aria-label="جستجوی تونل">
    </div>
    <select class="rt-select" aria-label="فیلتر وضعیت">
        <option>همه وضعیت‌ها</option>
        <option>فعال</option>
        <option>متوقف</option>
    </select>
    <button class="rt-secondary-button" type="button">↻ بروزرسانی</button>
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
            <button class="rt-primary-button" type="button">+ افزودن تونل</button>
        </div>
    @else
        <div class="rt-table-wrap">
            <table class="rt-table rt-tunnel-table">
                <thead>
                    <tr>
                        <th>نام</th>
                        <th>نوع</th>
                        <th>سرور</th>
                        <th>وضعیت</th>
                        <th>عملیات</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($tunnels as $tunnel)
                    <tr>
                        <td><strong>{{ $tunnel['name'] }}</strong></td>
                        <td>{{ $tunnel['type'] }}</td>
                        <td>{{ $tunnel['host'] }}</td>
                        <td><span class="rt-status is-online">فعال</span></td>
                        <td class="rt-actions">
                            <button class="rt-action-button" type="button">شروع</button>
                            <button class="rt-action-button" type="button">توقف</button>
                            <button class="rt-action-button" type="button">ری‌استارت</button>
                            <button class="rt-more" type="button">•••</button>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    @endif
</section>
@endsection
