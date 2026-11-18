# Pemeriksaan pesanan, sinkronisasi, dan GPS — 18 November 2026

## Perubahan

- Runtime dan formulir membatasi nama penerima 200 karakter serta alamat/rincian barang 2.000 karakter sesuai validasi SQL. Whitespace di tepi input dibuang sebelum penyimpanan; panjang dihitung sebagai Unicode code points seperti PostgreSQL. Batas uang, box, WhatsApp, dan koordinat tetap berlaku.
- Perjalanan menolak pilihan kosong atau lebih dari 20 pesanan sebelum mengubah data.
- Penolakan validasi SQL (P0001, kelas 22/23) menahan operasi lewat penanda pemeriksaan yang sudah tersedia pada outbox. Payload dan ID operasi dipertahankan. Perubahan berikutnya diblokir sampai rekonsiliasi manual; tidak ada penghapusan antrean atau penerapan snapshot server otomatis.
- Beranda menampilkan alasan antrean tertahan. Gangguan koneksi, masalah sesi/akses, dan kegagalan server memiliki pesan berbeda. Alasan penolakan permanen bertahan setelah runtime dimuat kembali. Rekonsiliasi belum memiliki tombol penyelesaian otomatis; catatan dapat disalin untuk diperiksa.
- Setelah sinkronisasi membaca snapshot, ruas GPS disesuaikan dengan perjalanan aktif; perjalanan yang sudah disetor menghentikan GPS. Hasil persiapan cache ruas yang kedaluwarsa diabaikan.
- Pergantian ruas tidak membatalkan permintaan izin GPS yang masih berlangsung. Stop membatalkan hasil start lama tanpa mengganggu start berikutnya. Stream lokasi yang selesai ditandai terputus dan tracking berhenti. Pembatalan subscription lama tidak menghapus subscription baru.
- Resume aplikasi membatalkan timer sinkronisasi sebelumnya sebelum membuat timer baru.

Tidak ada perubahan skema/kontrak Supabase, provider peta, optimasi urutan tujuan, atau desain layar utama. Google Maps tetap nonaktif. APK menggunakan flavor production, bukan demo.

## Pemeriksaan otomatis

- `test/courier_runtime_test.dart`: input melebihi batas ditolak sebelum masuk outbox, batas maksimum diterima, trimming, pilihan perjalanan kosong, alur dua pesanan pada satu pin, pesanan baru ketika trip aktif, LIFO, pembayaran kurang, setoran prematur dan riwayat.
- `test/courier_sync_test.dart`: mock HTTP melalui SupabaseClient untuk offline, sesi kedaluwarsa, penolakan SQL, konflik revisi dan respons hilang setelah commit. Runtime dimuat ulang sebelum retry; ID operasi sama, revisi mock server bertambah sekali, payload lokal tetap tersimpan. Penolakan/konflik bertahan setelah reload dan tidak dikirim berulang. Ini bukan pengujian server hosted baru.
- `test/gps_navigation_test.dart`: pergantian tujuan saat menunggu izin, stop/start ketika izin tertunda, stream selesai, kualitas posisi, urutan sampel, kedatangan, kegagalan reroute, throttle dan respons terlambat.
- Tes penyimpanan memakai database SQLite sementara; tes GPS memakai sumber lokasi tiruan. Bukti hasil suite dan analyzer berada pada `build/orders_gps_all_tests.log` dan `build/orders_gps_analyze.log`.

## Uji HP yang masih diperlukan

Gunakan akun uji tersendiri dan lokasi pengantaran yang aman. Lakukan saat berhenti; jangan operasikan HP sambil berkendara.

1. Pasang APK sebagai pembaruan, login, tambah dua pesanan pada satu pin dan satu pesanan pada pin berbeda. Periksa alamat, jumlah box dan nominal dengan pemisah ribuan.
2. Pilih pesanan, verifikasi muatan, hitung rute dan mulai perjalanan. Izinkan lokasi; pastikan posisi kurir dan seluruh ruas tampil.
3. Tambah pesanan ketika perjalanan aktif. Pesanan masuk antrean berikutnya, urutan perjalanan aktif tetap sama.
4. Bergerak dengan aman, pindah ke Maps/WhatsApp, lalu kunci layar sekitar 10 menit. Periksa notifikasi perjalanan dan posisi setelah aplikasi dibuka kembali. Catat model HP, versi Android, izin dan pengaturan baterai jika posisi berhenti.
5. Matikan GPS, tolak/cabut izin, dan pulihkan. Status harus menjelaskan kendala; aktivasi ulang tidak membuat pelacakan ganda atau menghilangkan rute.
6. Putuskan internet, selesaikan pengantaran dan pembayaran secara manual. Tutup/buka aplikasi, pastikan riwayat dan antrean tetap ada; nyalakan internet lalu periksa sinkronisasi dan tidak ada transaksi ganda. Perhitungan rute baru memerlukan internet.
7. Selesaikan semua pesanan, konfirmasi kembali ke depot, lakukan setoran. GPS harus berhenti; riwayat tetap ada dan pesanan tambahan siap untuk perjalanan berikutnya.
8. Jika memakai akun pada dua perangkat, uji konflik dengan data uji. Pastikan alasan ditampilkan dan catatan dapat disalin; hentikan pengujian konflik untuk rekonsiliasi manual.

## Batas hasil

GPS bergerak, izin Android asli, layar terkunci, pemulihan proses yang dibunuh OS, dan interaksi fisik belum dibuktikan pada tahap ini. Uji fisik ditunda sesuai permintaan pengguna. APK release uji masih memakai sertifikat debug lokal yang sama seperti build sebelumnya.

## Hasil pemeriksaan

- PASS, regresi: 98 tes Flutter lulus (`build/orders_gps_all_tests.log`).
- PASS, analisis pada lingkup perubahan: tidak ada error/warning; 55 info deprecation impor Material yang sudah ada di SDK (`build/orders_gps_analyze_final.log`). Exit analyzer nonzero karena info tersebut.
- PASS, purpose: pesan baru memberi alasan antrean tertahan dan tindakan salin catatan yang sudah tersedia; tidak menambah dekorasi atau kontrol baru.
- PASS, identitas pada lingkup perubahan: memakai widget, tipografi Inter, charcoal/lime serta layout FigCraft yang ada; ENERGY 2 / RHYTHM 2 / MOTION 1 mengikuti acuan sebelumnya.
- Pemeriksaan di atas tidak menyatakan GPS fisik atau seluruh interaksi pada HP telah diuji.
- PASS, pesan dan kontrol yang berubah: dua tes UI tambahan dalam suite UI yang ada lulus pada 393×852 dan 320×640 (skala teks 1,6), termasuk menampilkan alasan penolakan serta menekan tombol salin dan memeriksa isi clipboard (`build/orders_gps_ui_tests.log`). Preview `build/orders_gps_previews/live_sync_blocked_393.png` dan `live_sync_blocked_320.png` diperiksa secara visual; teks membungkus dan tombol dapat dijangkau. Tile pada tes memakai renderer offline.
- PASS, build Android: log Flutter mencatat Built app-production-release.apk (64,0 MiB), Gradle 317,9 detik. Paket com.browcyl.kurir_go, versi 1.0.0, versionCode 2, tiga ABI. PowerShell melaporkan exit nonzero karena warning native di stderr, tetapi Flutter mencatat build selesai dan artefak diperiksa terpisah.
- PASS, artefak: apksigner memverifikasi tanda tangan v2 sertifikat debug lokal; aapt2 memastikan flavor utama/versionCode 2 dan tanpa flag application-debuggable. Salinan pada Bagikan-KurirGO-Utama-2026-11-18 memiliki SHA256 sama dengan sumber.
