# SIA Mobile Soosvaldo

<p align="center">
  <img src="logo/Logo.png" alt="Logo" width="120" />
  <img src="logo/Title.png" alt="Title" height="40" />
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white"/></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white"/></a>
  <a href="https://www.php.net/"><img src="https://img.shields.io/badge/PHP-8.x-777BB4?logo=php&logoColor=white"/></a>
  <a href="https://www.mysql.com/"><img src="https://img.shields.io/badge/MySQL-5.7%2F8.0-4479A1?logo=mysql&logoColor=white"/></a>
  <img src="https://img.shields.io/badge/Made%20with-%F0%9F%92%9C-purple"/>
</p>

## Ringkasan
Aplikasi Flutter untuk kebutuhan kasir/akuntansi sederhana: barang, customer, membership, POS (nota jual), piutang/cicilan, dan laporan akuntansi. Frontend Flutter terhubung ke API PHP/MySQL.

## Fitur Utama
- 🔐 Login & session karyawan
- 📊 Dashboard metrik bisnis
- 📦 Manajemen Barang
- 🧑‍🤝‍🧑 Customer & Karyawan
- ⭐ Membership & Metode Pembayaran
- 🧾 POS (Nota Jual)
- 💸 Piutang & Cicilan
- 📚 Akuntansi: Jurnal Umum, Buku Besar, Neraca Saldo

## Quick Start
1. Install depedensi: `flutter pub get`
2. Jalankan aplikasi:
   - Windows: `flutter run -d windows`
   - Web: `flutter run -d chrome`
   - Android: emulator/HP tersambung lalu `flutter run`
3. Base URL API ada di `lib/app_config.dart` → `AppConfig.baseUrl`
   - Default: `https://siamobal.soosvaldo.my.id/api/`
   - Untuk lokal: misal `http://localhost/sia_mobile_soosvaldo/api/`

## Konfigurasi Backend (PHP/MySQL)
1. Pindahkan folder `api/` ke server PHP (contoh XAMPP: `C:/xampp/htdocs/sia_mobile_soosvaldo/api`).
2. Edit kredensial DB di `api/config.php` (`$host`, `$user`, `$pass`, `$db`).
3. Import `Database.sql` ke MySQL.
4. Tes endpoint: buka `http://localhost/sia_mobile_soosvaldo/api/get_barang.php` (harus JSON).

## Screenshots (sementara)
<p>
  <img src="logo/Logo%20%2B%20Title.png" alt="Logo + Title" width="480" />
</p>

## Build & Test
- Build APK: `flutter build apk --release`
- Build Web: `flutter build web`
- Test: `flutter test`

## Troubleshooting (cepat)
- 🔌 Tidak bisa konek: cek `AppConfig.baseUrl` dan akses API dari perangkat.
- 🛡️ CORS: sudah diatur di `api/config.php`, pastikan server mengizinkan `OPTIONS`.
- 🧪 JSON error: cek log PHP (atau `api_logs/`) dan validasi data DB.

## Roadmap Ringan
- [ ] Tambah lebih banyak screenshot UI
- [ ] Mode gelap (dark mode)
- [ ] Konfigurasi environment (dev/staging/prod) untuk `AppConfig.baseUrl`
