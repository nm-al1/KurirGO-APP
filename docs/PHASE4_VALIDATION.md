# Validasi demo KurirGO

Validasi terakhir: 16 November 2026. Menggantikan laporan Fase 4 sebelumnya.
Lingkungan: Windows, Flutter 3.47.9, Dart 3.13.7.

## Hasil pemeriksaan

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze` | PASS, tidak ada masalah setelah dua perbaikan lint |
| `flutter test` | PASS, 64 tes |
| `flutter test test/map_resilience_test.dart` | PASS, 2 tes diulang setelah perbaikan |
| `flutter build apk --debug` | PASS, APK debug berhasil dibangun |
| `codegraph sync .` | PASS, indeks sudah mutakhir |
| `flutter devices` | Hanya Windows dan Chrome; tidak ada Android terhubung |
| `flutter emulators` | Tidak ada sumber emulator Android tersedia |

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Perubahan kode terbatas pada penambahan kurung kurawal blok `if` di peta dan
penghapusan import tes redundan. Tidak ada perubahan API atau dependensi.

## Cakupan tes otomatis

- Login, dashboard, verifikasi muatan, preview rute, pembayaran, riwayat,
  konfirmasi setoran, rute baru, serta registrasi lokal dan SOP.
- Struktur data, algoritma, penjagaan verifikasi/setoran, pembayaran
  COD/Tunai/QRIS/Transfer, penolakan uang kurang, dan perhitungan kembalian.
- Simulasi Putar/Jeda/Ulangi, penghentian saat aplikasi di latar belakang,
  pergantian tujuan, serta data tiga segmen termasuk kembali ke depot.
- Interaksi peta dan fallback saat tile gagal; posisi penanda di bawah HUD
  pada lebar 320 px dengan skala teks 1,6.
- Render tujuh layar pada 393×852 dan 320×640, teks besar, serta aksesibilitas
  login. Ini bukan audit visual manual seluruh layar.
- URI eksternal dan fallback kegagalan dengan pembuka yang dimock.

Tes peta gagal sengaja memasukkan gambar rusak dan mencetak `Invalid image data`;
kedua tes ketahanan peta tetap lulus. Build mencetak peringatan ketidakcocokan
versi XML Android SDK (pembaca versi 3 menemukan versi 4), tetapi selesai sukses.
Kotlin incremental compilation tetap dinonaktifkan karena lokasi proyek C:
dan pub cache D:; build dapat lebih lambat.

## Kondisi demo dan batas validasi

Inter asli dan lisensi OFL dibundel di `assets/fonts/`; tes presentasi memuat
font yang sama. Preview dapat dibuat dengan:

```powershell
flutter test test/presentation_test.dart --dart-define=PREVIEW_DIR=design/previews
```

Preview tidak dibuat ulang pada validasi ini karena tidak ada perubahan visual.
Tile widget test menggunakan gambar lokal, bukan peta online.

Uji manual Android, tile online, dan pembukaan Google Maps di perangkat masih
tertunda karena perangkat/emulator tidak tersedia. Setelah Android tersedia,
jalankan `flutter run -d <id-perangkat-android>` dan uji alur lengkap di atas,
kontrol simulasi, serta tombol Google Maps termasuk tujuan kembali ke depot.

Autentikasi dan registrasi berada di memori; akun lokal hilang saat proses
dimulai ulang. Pembayaran non-tunai adalah konfirmasi manual. GPS perangkat,
gateway pembayaran, dan build iOS tidak diuji atau ditambahkan pada pekerjaan ini.

Detail navigasi: [NAVIGATION_VALIDATION.md](NAVIGATION_VALIDATION.md).
