# Validasi implementasi 16 November 2026

## Acuan dan perubahan

Acuan visual: `design/KurirGO_Final_UI.figcraft`, logo hasil ekspor, Inter, charcoal `#18181B`, lime `#C6FF00`, permukaan putih/slate, kartu muatan gelap, ilustrasi box dan navigasi bawah. Empat tab diminta pengguna: Home, Riwayat, Performa, Profil. Struktur formulir berkembang untuk email, password, alamat bebas, dan pin. Desain ini tidak diklaim identik per piksel dengan frame lama yang hanya memiliki dua pesanan demo.

ENERGY 2 / RHYTHM 2 / MOTION 1. Aksen lime menandai aksi utama dan rute. Transisi halaman 220 ms dan tab 180 ms memakai fade; reduced motion menonaktifkan transisi tersebut. Simulasi memiliki kontrol putar/jeda dan berhenti saat aplikasi berada di background.

## Bukti pemeriksaan

Hasil akhir suite Flutter: **76 tes lulus**. `flutter analyze` diperiksa terpisah. Build Android debug dan build web berhasil; build APK akhir diulang setelah pemeriksaan perubahan terakhir.

- `test/number_format_test.dart`: parser rupiah/koordinat, penolakan nilai negatif/desimal uang, pengelompokan, penyisipan kursor, backspace dan pengosongan.
- `test/courier_store_test.dart`: pembayaran/outbox bertahan sesudah restart database, pemisahan dua akun, perlindungan data tertunda terhadap pull server, konflik, rollback saat journal gagal, dan penolakan snapshot usang.
- `test/courier_runtime_test.dart`: pesanan berikutnya tetap antre, dua pesanan satu stop tetap terpisah, urutan LIFO, kurang bayar, referensi non-tunai, larangan edit pesanan aktif, setoran, dan riwayat tetap ada setelah perjalanan berikutnya.
- `test/route_service_test.dart`: table distances, penggabungan koordinat, geometry tertutup, kegagalan layanan dan tujuan tidak terjangkau.
- `test/production_ui_test.dart`: login/registrasi, validasi kosong, empat tab, formulir pesanan, input rupiah dan keyboard; 393×852 serta 320×640 dengan skala teks 1,6 dan reduced motion. Preview berada di `build/production_previews`.
- `supabase/tests/courier_state.sql`: PostgreSQL 17 lokal serta project Supabase yang terhubung, transaksi rollback. Memeriksa RLS dua akun, larangan direct write, lookup email privat, retry idempoten, konflik revisi, kurang bayar, riwayat immutable, setoran prematur, username unik, dan rate limit. Tidak meninggalkan akun uji.
- Migrasi `202611160001_courier.sql`, fungsi `username-login`, dan konfigurasi auth telah dipasang ke project `joddamojsxuwovltrsdq` melalui CLI terautentikasi.
- Endpoint login menolak kredensial tidak valid dengan HTTP 401.

## Batas verifikasi

Gate antislop untuk perubahan visual yang diperiksa:

- PASS, hard gate visual: preview login, registrasi, empat tab, formulir, verifikasi dan navigasi pada dua ukuran tidak menimbulkan exception overflow dalam widget test. Konten performa berasal dari catatan akun; kondisi kosong tidak menampilkan statistik rekaan.
- PASS, purpose: lime untuk aksi/rute, charcoal untuk kartu muatan dan navigasi; box isometrik berasal dari komponen produk. Tidak ada gradient/glow tambahan.
- PASS, liveliness: ENERGY 2 / RHYTHM 2 / MOTION 1; kartu muatan, CTA dan motif box membentuk hirarki sesuai referensi.
- PASS, craft pada lingkup yang diuji: label/hint formulir, validasi, empat tab, keyboard dan reduced motion diperiksa otomatis. Pemeriksaan klik seluruh kontrol pada perangkat fisik belum dilakukan; gate ini tidak menyatakan verifikasi perangkat lengkap.

Penerimaan email verifikasi/recovery, login akun pengguna sungguhan, tile jaringan dan intent Google Maps/WhatsApp/telepon di Android fisik memerlukan pemeriksaan perangkat dan email pengguna. Tidak ada klaim pengujian perangkat tersebut. Pembayaran non-tunai berupa konfirmasi manual terhadap pembayaran resmi; bukan gateway.

Konflik antarperangkat disimpan dan dapat disalin untuk rekonsiliasi manual. Snapshot maksimal 20 MB dan endpoint OSRM publik digunakan untuk pengembangan. Rincian operasional tersedia di `SUPABASE_SETUP.md`.
