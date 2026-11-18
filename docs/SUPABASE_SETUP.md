# Akun dan sinkronisasi KurirGO

Aplikasi utama memakai Supabase dan SQLite. Mode demo lama hanya aktif dengan `flutter run --dart-define=DEMO_MODE=true`; akun demo tidak dimasukkan ke server.

## Menjalankan aplikasi

```powershell
flutter pub get
flutter run
flutter build apk --debug
```

URL dan publishable key project KurirGO menjadi default konfigurasi klien. Untuk project lain, gunakan `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...`. Service role hanya tersedia di Edge Function, tidak dibundel dalam APK.

## Memasang ulang backend

```powershell
npx supabase login
npx supabase link --project-ref joddamojsxuwovltrsdq
npx supabase db push --remote --dry-run
npx supabase db push --remote --yes
npx supabase functions deploy username-login --remote=joddamojsxuwovltrsdq --yes
npx supabase config push --project-ref joddamojsxuwovltrsdq --yes
```

Konfigurasi auth menetapkan password minimal 8 karakter, verifikasi email, dan redirect Android/iOS `com.browcyl.kurirgo://login-callback/`. Untuk web, tambahkan origin deployment sebenarnya pada daftar redirect Supabase. Pengiriman email bergantung pada konfigurasi dan batas layanan email Supabase; uji penerimaan email dengan alamat pengguna sebelum operasional.

Registrasi membuat username unik melalui trigger. Username tidak dapat diubah; nama dan WhatsApp dapat diedit. Login username memakai lookup email privat dan pembatasan percobaan per username/IP, lalu Supabase Auth memeriksa password. Aplikasi tidak menyimpan password dalam tabel sendiri.

## Penyimpanan offline

Cache dan outbox SQLite dipisahkan dengan ID akun. Setiap perubahan pesanan, pembayaran, dan setoran disimpan bersama operasi sinkronisasi dalam transaksi lokal. Server memakai ID operasi dan revisi untuk mencegah pengulangan pembayaran. Riwayat selesai tidak dapat diedit atau dihapus melalui RPC.

Sinkronisasi berjalan saat membuka aplikasi, kembali ke foreground, setiap 30 detik selama foreground, dan lewat tombol sinkronisasi. Aplikasi yang ditutup tidak menjanjikan sinkronisasi latar belakang. Logout diblokir selama masih ada operasi tertunda. Konflik revisi menghentikan perubahan baru dan menyimpan seluruh catatan lokal; tombol salin menyediakan catatan untuk rekonsiliasi manual, tanpa menimpa data server.

Pesanan baru dapat dibuat offline. Perhitungan rute baru membutuhkan internet. Geometry jalan tersimpan sebelum perjalanan dimulai. Peta dasar tetap membutuhkan jaringan dan tidak dijamin tersedia offline.

## Rute dan pembayaran

Pilih 1–20 pesanan. Pin sama berbagi stop, sedangkan pengantaran dan pembayaran tetap terpisah. Held–Karp digunakan sampai 10 tujuan unik, Nearest Neighbor + 2-Opt di atasnya. Rute selalu kembali ke depot `-5.1560, 119.4350`. Kegagalan layanan jalan menghentikan perhitungan, tanpa mengganti jarak dengan garis lurus.

Endpoint pengembangan adalah `https://router.project-osrm.org`. Untuk penggunaan operasional, konfigurasi layanan sendiri lewat `--dart-define=OSRM_URL=https://...`; endpoint harus menyediakan table distances dan route steps GeoJSON. Data tiles menggunakan OpenStreetMap dengan atribusi. Penggunaan layanan publik mengikuti kebijakan penyedianya.

Posisi rider tetap simulasi. Google Maps tersedia untuk navigasi eksternal. QRIS/transfer dicatat setelah kurir memeriksa pembayaran pada kanal resmi; aplikasi tidak membuat QR pembayaran atau terhubung ke payment gateway.

Nilai uang disimpan sebagai integer rupiah. Tampilan dan input menggunakan `150.000`, `Rp 150.000`, dan desimal `28,5`. Koordinat, nomor telepon, ID, dan password tidak memakai pengelompokan ribuan.

## Batas implementasi

Server menyimpan snapshot akun dengan jurnal transaksi, bukan tabel terpisah per pesanan. Batas snapshot 20 MB; tiap mutasi lokal menyimpan snapshot dalam outbox sampai diakui server. Arsip sangat besar membutuhkan migrasi ke sinkronisasi per entitas. Konflik antarperangkat memerlukan rekonsiliasi manual. Jangan menghapus data aplikasi saat ada catatan yang belum tersinkron.

## Pencarian lokasi dan foto profil

Konfigurasi Geoapify, Storage privat, dan hasil pengujian: [LOCATION_PROFILE_VALIDATION.md](LOCATION_PROFILE_VALIDATION.md). Secret backend memakai nama GEOAPIFY_API_KEY; key demo dikonfigurasi terpisah saat build.


Integrasi Google opsional dan setup billing: [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md). Default tetap Geoapify sampai konfigurasi Google aktif.
