# Handoff UI FigCraft — 16 November 2026

## Perubahan

- Dokumen referensi disimpan sebagai `design/KurirGO_Final_UI.figcraft`.
- Dua logo asli diekspor ke `assets/brand/`; logo K menggantikan kotak kargo
  pada login. Wordmark menggunakan GO tegak sesuai referensi.
- Riwayat kini memakai bidang terang dan kartu setoran gelap, total pembayaran
  dari controller, serta timeline pesanan selesai.
- Tab Home/Performa/Profil terhubung ke halaman data sesi dan form edit nama/
  WhatsApp. Edit memvalidasi input dan mempertahankan kredensial login.
- Map dan logika navigasi tidak diubah. Inter dipakai sebagai asumsi font
  karena referensi hanya menyimpan teks sebagai outline vektor.

## Batas kesesuaian desain

Ini adaptasi layout responsif dengan data demo yang tersedia. Foto kurir,
peringkat, grafik mingguan, OTP, kontak darurat dan ID mitra pada mockup belum
diimplementasikan. Halaman Performa secara eksplisit menyebut data sesi demo.
Profil lokal hilang saat proses aplikasi dimulai ulang.

## Verifikasi

- `flutter analyze`: tidak ada masalah.
- `flutter test --dart-define=PREVIEW_DIR=design/previews`: 66 tes lulus.

- Preview diperbarui pada 393×852 dan 320×640 dengan teks 1,6× untuk viewport
  kecil, termasuk tiga halaman baru. Hasil ada di `design/previews/`.
- Tes profil mencakup validasi, simpan, propagasi nama ke dashboard, dan navigasi
  Performa/Home. Tes akun memastikan PIN lama tetap berlaku setelah edit.
- Logo hasil ekspor diperiksa visual, rasio asli dipertahankan, dan PNG dirender
  di preview login. Aset logo horizontal tersedia untuk penggunaan berikutnya.
- Tidak ada uji Android langsung karena perangkat/emulator belum tersedia.

## Pemeriksaan Antislop pada perubahan ini

- Hard gate PASS dalam cakupan tes: preview responsif tidak melaporkan overflow;
  tes login/keyboard dan alur pembayaran tetap dijalankan; kontrol baru terhubung
  ke navigasi atau form, dan validasi nama/telepon memiliki pesan kesalahan.
- Purpose gate PASS: charcoal untuk ringkasan, putih untuk isi, lime untuk CTA;
  ikon Material menunjukkan tujuan navigasi dan status pesanan.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1, logo K asli, header ringkasan
  menjadi fokus, dan jarak antarkelompok memisahkan ringkasan dari data pesanan.
- Craft PASS dalam cakupan otomatis: form menyimpan ke akun sesi, data performa
  berasal dari controller, dan rating/riwayat mingguan yang belum tersedia diberi
  keterangan. Audit aksesibilitas manual seluruh layar belum dilakukan.
