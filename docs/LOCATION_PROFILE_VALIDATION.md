# Lokasi penerima dan foto profil

Layout mengikuti FigCraft dengan kontrol pencarian dan foto ditempatkan pada halaman yang ada. Tidak ada aset dekoratif baru. Data koordinat tetap disimpan untuk routing; field koordinat tidak ditampilkan.

## Konfigurasi
- Supabase project joddamojsxuwovltrsdq: Edge Functions > Secrets, tambahkan `GEOAPIFY_API_KEY`.
- Fungsi `geocode` memvalidasi sesi via Auth, input, dan batas 30 permintaan per menit per akun. Key server tidak masuk APK.
- Demo lokal memakai `--dart-define=GEOAPIFY_DEMO_KEY=...` saat build bersama `--dart-define=DEMO_MODE=true`. Gunakan key terpisah berkuota terbatas: key APK dapat diekstrak. Jangan commit key.
- Tanpa key/koneksi, pemilihan pin dan alamat manual tetap tersedia. Saran alamat dan reverse geocoding membutuhkan layanan aktif.
- Bucket privat `courier-avatars`, JPG maksimal 2 MB, folder ID akun. SELECT/INSERT/DELETE hanya pemilik. Tidak ada akses publik.

## Perilaku
Cari minimal 3 karakter, jeda 500 ms, maksimal 5 saran Indonesia dengan prioritas Makassar. Geser peta atau ketuk untuk memilih pin; alamat diperbarui sesudah jeda 600 ms. Respons lama diabaikan. Konfirmasi mengembalikan pin dan alamat, pembatalan tidak mengubah pesanan. Alamat dapat ditambah nomor rumah/patokan; perubahan teks tidak memindahkan pin.

Foto dipilih dari galeri, dinormalisasi JPG maksimal sisi 512, EXIF dibuang, pratinjau sebelum simpan. Nama/nomor tetap divalidasi. Foto baru diunggah lebih dulu, metadata diperbarui, lalu foto lama dihapus; gagal metadata mencoba menghapus unggahan baru. Demo menyimpan foto di cache lokal per akun, reset demo membersihkannya. Home/Profil/Ubah Profil memakai avatar bersama. Android lost picker diteruskan ke Ubah Profil ketika Home dibuka kembali.

## Pemeriksaan
- 87 tes Flutter lulus (`build/location_profile_full_tests.log`), termasuk respons pencarian/reverse terlambat dan layar 320 px, teks 1.6, keyboard terbuka.
- Analyzer: tidak ada error/warning; 53 info deprecation impor Material dari Flutter 3.50. `flutter analyze` tetap berstatus nonzero karena info tersebut. Tidak dilakukan migrasi seluruh UI ke paket Material baru dalam perubahan fitur ini.
- Hosted: migrasi 202611170001 dan fungsi geocode sudah terpasang. Secret Geoapify dikonfigurasi pengguna; pencarian Pantai Losari menghasilkan 5 hasil dan reverse geocoding 1 hasil.
- Hosted SQL rollback: dua akun, baca/insert objek milik akun lain ditolak, batas 30 permintaan per menit dan isolasi hitungan antar akun lulus (`supabase/tests/locations_avatars.sql`).
- Storage API nyata: upload/download/delete foto uji oleh pemilik lulus; download tanpa autentikasi ditolak. Objek uji dihapus sesudah pengujian, profil akun tidak diganti.
- Pratinjau `build/location_profile_previews/live_edit_profile_320.png` dan `live_add_order_320.png` diperiksa. Layout mengikuti komponen FigCraft; tidak ada overflow pada pemeriksaan widget. Pesan koneksi pada preview berasal dari backend offline pada tes.
- Uji galeri fisik dan pemulihan proses Android belum dilakukan: HP tidak terhubung setelah laptop menyala kembali. Demo memerlukan key Geoapify khusus build agar pencarian online aktif.

## Delivery Gate
Arah: FigCraft charcoal/lime/Inter yang sudah disetujui. Kontrol pencarian untuk memilih tujuan; avatar untuk identitas kurir. Tidak membuat aset dekoratif. Bukti: tes layar kecil dan pratinjau di atas. Batas: pratinjau tes memakai tile offline, bukan validasi visual peta jalan nyata atau izin galeri perangkat.

APK operasional debug berhasil dibangun: `build/app/outputs/flutter-apk/app-production-debug.apk` (17 November 2026, 20:29 WITA). SDK lokal Flutter 3.50; build mengeluarkan peringatan versi Gradle/AGP/Kotlin dan SDK XML, tanpa kegagalan kompilasi. APK demo debug juga berhasil dibangun: `build/app/outputs/flutter-apk/app-demo-debug.apk` (20:32 WITA). Build demo ini belum berisi GEOAPIFY_DEMO_KEY: pencarian online belum aktif, pemilihan pin/alamat manual serta foto lokal tersedia.
