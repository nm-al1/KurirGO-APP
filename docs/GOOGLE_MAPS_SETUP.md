# Google Maps / Google Places (Android)

Status: integrasi disiapkan; belum diaktifkan karena setup billing pengguna gagal OR_BACR2_59. Default `USE_GOOGLE_MAPS=false`: Flutter run tetap memakai OpenStreetMap/Geoapify yang sudah aktif. Jangan nyatakan Perdosfit ditemukan sebelum tes Google langsung.

## Google Cloud
1. Buat/pilih project KurirGO, aktifkan billing.
2. Enable Maps SDK for Android, Places API (New), Geocoding API.
3. Key server: API restrictions Places API (New) dan Geocoding API; application restriction jangan Android karena pemanggilan dari server Supabase. Simpan di Supabase Edge Functions Secrets: GOOGLE_MAPS_SERVER_KEY. Jangan taruh key server dalam APK.
4. Key Android: application restrictions Android apps, API restriction Maps SDK for Android. Tambahkan package com.browcyl.kurir_go dan com.browcyl.kurir_go.demo dengan SHA-1 debug laptop ini:
   DF:BB:C7:29:3C:DC:46:62:33:1B:14:45:16:DF:35:05:28:4F:17:91
   Untuk release gunakan SHA-1 sertifikat release, bukan debug.
5. Salin android/maps.properties.example menjadi android/maps.properties (diabaikan Git), isi GOOGLE_MAPS_ANDROID_KEY dengan key Android. Bisa juga environment GOOGLE_MAPS_ANDROID_KEY. Key Android masuk manifest APK dan harus dibatasi package/sertifikat.
6. Fungsi google-geocode sudah dideploy terpisah. Fungsi geocode lama tetap tersedia untuk APK lama/default Geoapify.
7. Setelah konfigurasi aktif: flutter run --dart-define=USE_GOOGLE_MAPS=true (pilih device Android). Build produksi: flutter build apk --debug --flavor production --dart-define=USE_GOOGLE_MAPS=true.

## Alur dan batas
Autocomplete menggunakan session token UUID, lokasi prioritas Makassar, hasil Indonesia, maksimal 5. Hanya pilihan pengguna mengambil Place Details (mask id,location), lalu Geocoding mengambil alamat. Nama usaha dari autocomplete bersifat sementara; alamat penerima berasal dari Geocoding dan dikonfirmasi pengguna. Jangan menjadikan hasil ini indeks tempat bersama. Penyimpanan pesanan tetap per akun.

Google Maps dipakai untuk pin, preview rute dan navigasi Android. Perangkat non-Android menampilkan status belum tersedia. GPS/OSRM/Held-Karp dan urutan muatan tetap dipertahankan. Semua leg rute ditampilkan, hanya leg aktif diganti saat reroute. Penanda memakai charcoal/lime, tombol follow/overview/zoom tetap tersedia. Sumber rute ditampilkan sebagai OSRM/optimasi KurirGO.

Tanpa key Android, peta menampilkan status konfigurasi dan tidak mencoba membuat native map. Key tidak valid atau billing gagal masih memerlukan pemeriksaan log SDK/perangkat; gate hanya memeriksa key tidak kosong. Google API pencarian memerlukan sesi pengguna dan dibatasi RPC 30 permintaan per menit. Field detail dipanggil hanya untuk pilihan pengguna, bukan seluruh saran.

Demo lokal: bila Google aktif, peta memakai key Android yang sama dengan package demo yang diizinkan. Pencarian backend memerlukan akun operasional; demo lokal menggunakan pin manual/data dummy. Jangan menanam key server Google dalam APK demo. Mode default Geoapify tetap mendukung GEOAPIFY_DEMO_KEY seperti sebelumnya.

## Validasi
Tes model sesi/pilihan, komposisi semua leg GPS, bounds dan UI ada dalam test/google_maps_service_test.dart serta tes pin/rute yang sudah ada. Preview widget memakai fixture offline, bukan bukti Google Maps native sudah bekerja. Wajib uji langsung Perdosfit, reverse pin, izin GPS, kamera/zoom/follow, dan navigasi pada Android setelah billing/key aktif.

## Billing gagal
Panduan: https://docs.cloud.google.com/support/docs/troubleshoot-signup
Cek data nama/alamat sesuai bank, kartu mendukung pembayaran internasional dan berulang, dan ikuti verifikasi profil Google Payments bila diminta. Coba tanpa VPN/proxy, incognito/ekstensi dimatikan. Bila tetap gagal: https://support.google.com/cloud/contact/cloud_platform_suspensions
Kode OR_BACR2_59 tidak cukup untuk menentukan sebab spesifik tanpa pemeriksaan Google. Tidak ada jaminan bahwa mengganti kartu/browser menyelesaikannya.

Pemeriksaan sejauh ini: 89 tes lengkap lulus sebelum Google dinonaktifkan sebagai default; sesudah itu 8 tes terkait UI/service dan 3 tes service/batas rute lulus. Analyzer hanya melaporkan deprecation Material pada SDK Flutter lokal, tanpa error/warning. Native Google Maps dan Perdosfit belum diuji karena billing gagal dan key Android belum tersedia. Build Android default Geoapify diverifikasi terpisah; lihat log build/google_optional_build.log.

Pemeriksaan akhir: 90 tes lengkap lulus (`build/google_maps_all_tests_final.log`). Build APK production debug default Geoapify berhasil (`build/google_optional_build.log`, Gradle 360,6 detik). Integrasi Google tetap belum aktif; tidak ada uji langsung listing Perdosfit/Google Maps native tanpa billing dan key.
