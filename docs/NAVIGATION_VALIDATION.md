# Validasi navigasi demo

Tanggal: 16 November 2026.

## Perilaku implementasi

- Peta dasar memakai tile OpenStreetMap online. Geometri dan instruksi belokan
  dimuat dari `assets/routes/makassar_loop.json`, sehingga tidak memerlukan
  permintaan routing baru saat simulasi berjalan.
- Data OSRM tersimpan mencantumkan jarak 40.931,1 meter dan tiga segmen:
  Pettarani → Antang → Sudiang → Pettarani. Matriks akademis TSP menggunakan
  fixture terpisah dengan total 28,5 km. Angka tersebut bukan pengukuran BBM.
- HUD dan pergerakan mengikuti geometri tersimpan. Putar menjalankan simulasi
  20×, Jeda menghentikannya, dan Ulangi mengembalikan posisi segmen ke awal
  tanpa mereset pesanan atau pembayaran. Telemetri merupakan simulasi.
- Google Maps menerima koordinat tujuan dan posisi simulasi sebagai asal.
  Manifest Android tidak meminta izin lokasi; aplikasi tidak membaca GPS nyata.
- Ketika tile gagal, rute tersimpan dan kontrol tetap tersedia dengan pesan
  bahwa peta dasar tidak tersedia.

## Bukti pengujian

Suite `flutter test` lulus 64 tes. Tes navigasi mencakup koordinat awal/akhir
ketiga segmen termasuk depot, interpolasi, tiba di tujuan, putar/jeda/ulang,
pergantian tujuan, lifecycle latar belakang, dan interaksi peta. Tes ketahanan
peta juga diulang setelah perbaikan lint dan lulus 2 tes.

Tes URI memastikan parameter asal, tujuan, mode berkendara, dan aksi navigasi.
Pembuka eksternal dimock untuk menguji sukses/gagal serta fallback salin;
Google Maps sebenarnya tidak dibuka selama tes.

## Uji perangkat yang tertunda

Tidak ada Android terhubung atau emulator tersedia pada saat validasi.
Pembukaan aplikasi Maps nyata, tile online, dan alur kembali ke depot secara
manual perlu diuji di Android. Hasil tes widget tidak membuktikan integrasi
aplikasi eksternal di perangkat.

APK dan hasil pemeriksaan: [PHASE4_VALIDATION.md](PHASE4_VALIDATION.md).
