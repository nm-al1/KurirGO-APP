# Pemulihan layout FigCraft, 17 November 2026

Acuan tetap `design/KurirGO_Final_UI.figcraft` dan komponen awal sebelum integrasi akun/GPS. Layar operasional dan demo menggunakan `CourierHome`, `AuthPage`, `TripPreparation`, dan `TripPage` yang sama; tidak ada cabang layout alternatif untuk flavor demo. Tambahan demo berupa data lokal, penanda dan reset. Akses akun server tetap khusus operasional; editor profil juga bekerja lokal pada demo. Navigasi pengantaran sekarang memulai GPS pada kedua flavor, dengan simulasi sebagai pilihan tambahan demo.

## Susunan yang dipulihkan

- Dashboard: identitas kurir, kartu muatan gelap, mini-stepper, daftar box isometrik, empat tab dalam bilah hitam dan tombol muat tetap di bawah. Tambah pesanan, pilihan pesanan, edit, pembatalan dan sinkronisasi tetap tersedia.
- Login: logo K dan wordmark di bidang charcoal, formulir terang membulat. Registrasi dan edit profil memakai bidang terang dengan header/back dan badge, label serta placeholder tetap terlihat. Email dan password menggantikan PIN demo sesuai autentikasi saat ini.
- Verifikasi: header gelap, bidang terang membulat, petunjuk inspeksi dan kartu box, CTA bawah. Checklist LIFO dan preview map kembali menjadi dua tahap tampilan. Preview memiliki panel urutan, jalur pulang, dan tombol Mulai Navigasi tetap di bawah.
- Navigasi: peta memenuhi lebar, HUD gelap di atas, panel penerima/kasir gelap di bawah. Pengaturan GPS dan kontrol navigasi ditempatkan dalam panel expandable. Seluruh perbaikan polyline, follow/overview, rute jalan dan hitung ulang GPS tetap digunakan.
- Riwayat: kartu tunai/non-tunai, metrik dan timeline terang. Pencarian, tanggal dan detail permanen tetap tersedia. Performa memakai grafik batang tujuh hari dari jumlah box aktual, ringkasan dan penerimaan hari ini. Profil memakai kartu identitas gelap dan informasi operasional; tidak menambahkan rating atau statistik rekaan.

Ini pemulihan susunan visual responsif, bukan klaim identik piksel terhadap teks/vector mockup. Penambahan email, password, empat tab, pesanan dinamis dan kondisi kosong memerlukan konten yang berbeda dari contoh dua pesanan awal.

## Pemeriksaan

Preview 393×852 dan 320×640 dengan teks 1,6× berada di `build/restored_previews/`. Widget test memeriksa tab, form dan keyboard, layout muatan, langkah verifikasi menuju preview, dan layar navigasi tanpa overflow. Seluruh 83 tes Flutter lulus. Uji tambahan memastikan profil demo bertahan setelah reload, tetap tidak membuat outbox server, dan direset bersama data contoh. Analyzer bersih setelah perbaikan format blok.

Paket preview mencakup kondisi operasional kosong serta demo berisi enam pesanan dan riwayat tujuh hari. Tes menegaskan bahwa kedua mode memakai DeliverySummary dan FigcraftTabs yang sama. Jalur update profil demo menggunakan penyimpanan lokal; operasional tetap memakai Supabase Auth.

Tidak mengubah skema Supabase, akun, riwayat pengguna, atau aturan pembayaran. Tidak menghapus data aplikasi. APK demo dan production dibangun dengan ID masing-masing yang sudah dipakai. Perangkat tidak terhubung pada pemeriksaan 17 November; instalasi dan penilaian visual langsung di HP belum dilakukan.

## Gate visual pada lingkup yang diperiksa

- Hard gate PASS: preview dua ukuran dan skala teks besar lolos tanpa overflow; dropdown pembayaran dapat melebar/membungkus di dalam panel. Tidak ada statistik/rating fiktif tambahan.
- Purpose PASS: Inter, charcoal, lime, box isometrik, panel terang/gelap dan struktur layar berasal dari acuan yang disetujui.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1; kartu muatan dan CTA menjadi fokus, spasi memisahkan ringkasan, daftar, dan navigasi. Reduced motion tetap mematikan transisi halaman/tab.
- Craft PASS pada pemeriksaan otomatis: empat tab dan checklist menuju preview diuji, placeholder serta validasi tetap aktif, data backend dan data demo memakai layar bersama. Pemeriksaan seluruh kontrol dan tampilan pada perangkat fisik tetap belum dilakukan.
