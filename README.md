# Browcyl Delivery (KurirGO) 🛵📦

GPS Android dan demo terbaru: lihat [cara build, data contoh, dan batas pengujian perangkat](docs/GPS_DEMO_VALIDATION.md). Gunakan flavor `production` untuk akun Supabase atau `demo` dengan `DEMO_MODE=true` untuk data contoh lokal.

> **Implementasi 16 November 2026:** aplikasi utama sekarang memakai Supabase, SQLite/outbox, pesanan dinamis, empat tab navigasi, dan riwayat permanen. Lihat [panduan konfigurasi dan batas implementasi](docs/SUPABASE_SETUP.md). Keterangan akun/PIN lokal dan dua pesanan tetap di bawah berlaku untuk **mode demo** (`--dart-define=DEMO_MODE=true`).
### Sistem Optimasi Rute Pengantaran Tertutup (Closed-Loop TSP) & Manajemen Muatan Bagasi Motor

[![Flutter](https://img.shields.io/badge/Flutter-3.47.9-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.7-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Target](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen)](https://flutter.dev)
[![Figma](https://img.shields.io/badge/Figma-Pro%20Max%20UI-F24E1E?logo=figma&logoColor=white)](https://www.figma.com/design/cLq6mInWmssvSCQuaviNpc/Browcyl-Delivery---Final-UI-(Pro-Max))
[![Course](https://img.shields.io/badge/Academic-Struktur%20Data%20%26%20Desain%20Algoritma-orange)]()

---

## 📌 Sekilas Proyek

**Browcyl Delivery (KurirGO)** adalah aplikasi mobile kurir cerdas yang dirancang khusus untuk memecahkan kendala pengantaran kue brownies **Browcyl di Kota Makassar**.

Aplikasi ini menggabungkan:
1. **Verifikasi Muatan Berbasis Stack (LIFO):** Mencegah kurir membongkar bagasi motor di pinggir jalan; kotak kue untuk tujuan pertama (*Stop #1*) secara otomatis diposisikan di tumpukan teratas (*Top of Stack*).
2. **Kalkulasi Rute Tertutup Eksak (TSP Closed-Loop):** Mengoptimalkan rute fixture **Depot Pettarani ($V_0$)** → **Antang ($V_2$)** → **Sudiang ($V_1$)** → **Depot Pettarani ($V_0$)**. Matriks contoh menghasilkan 28,5 km; penghematan BBM belum diukur.
3. **Simulasi Navigasi:** Panduan belokan mengikuti geometri jalan tersimpan dengan kontrol Putar/Jeda/Ulangi pada kecepatan simulasi 20×. Posisi, kecepatan, dan akurasi bukan pembacaan GPS perangkat. Google Maps dapat dibuka untuk navigasi eksternal.
4. **Pencatatan Pembayaran Demo:** **COD**, **Cash Tunai**, **QRIS**, dan **Transfer Bank**, dengan kalkulator kembalian dan rekap setoran. Konfirmasi non-tunai dilakukan manual; belum terhubung ke gateway pembayaran.

---

## 🎨 Desain UI/UX (Figma Reference)

Desain antarmuka dirancang dengan standar kontras tinggi luar ruangan (*Outdoor High-Contrast*): **Matte Charcoal (`#18181B`)** dan **Electric Lime (`#C6FF00`)** (rasio kontras 14.5:1), tombol aksi 54px untuk pengoperasian dengan sarung tangan, serta geometri vektor 3D isometrik murni (*Zero AI Slop*).

👉 **[Buka File Figma Resmi: Browcyl Delivery - Final UI (Pro Max)](https://www.figma.com/design/cLq6mInWmssvSCQuaviNpc/Browcyl-Delivery---Final-UI-(Pro-Max))**

### 7 Layar Antarmuka KurirGO:
- **Screen 0A (`LoginScreen`):** Login demo lokal dengan username `ardiansyah` dan PIN `1234`; belum menggunakan server autentikasi.
- **Screen 0B (`RegisterScreen`):** Registrasi lokal dengan WhatsApp opsional. Data akun berada di memori dan hilang ketika proses aplikasi dimulai ulang.
- **Screen 1 (`DashboardScreen`):** Profil Kurir Ardiansyah, mini route stepper fungsional, kartu beban harian, dan manifest pesanan BRW-01 & BRW-02.
- **Screen 2 (`LoadVerificationScreen`):** Checklist inspeksi fisik bagasi kurir berlandaskan validasi struktur data LIFO (*Last-In, First-Out*).
- **Screen 3 (`RoutePreviewScreen`):** Visualisasi graf rute segitiga menyala di atas peta arteri Makassar & matriks jarak antar-outlet.
- **Screen 4 (`LiveNavigationScreen`):** Turn HUD belok kanan Jl. Antang Raya, polyline menempel aspal jalan (*snapped-to-road*), konsol kasir multi-metode (COD, Cash, QRIS, Transfer), serta One-Tap Intent Google Maps eksternal.
- **Screen 5 (`HistorySettlementScreen`):** Riwayat pengantaran, rekap tunai dan non-tunai dari pesanan selesai, serta konfirmasi setoran depot. Nominal merupakan data demo.

---

## 📚 Dokumen Spesifikasi Akademis & Teknis

Proyek ini dilengkapi dengan dokumentasi komprehensif di folder `docs/`:

| Dokumen | Deskripsi & Peruntukan |
| :--- | :--- |
| 📄 **[PRD.md](docs/PRD.md)** | **Product Requirement Document**: Visi produk, profil persona kurir & kasir, spesifikasi lengkap Kebutuhan Fungsional (FR-01 s/d FR-08) dan Non-Fungsional (NFR). |
| 🏗️ **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | **Blueprint Teknis untuk Codex**: Arsitektur Feature-First, diagram alur data, kontrak class interface, dan panduan tahap implementasi. |
| 🧮 **[ALGORITHM_ANALYSIS.md](docs/ALGORITHM_ANALYSIS.md)** | **Khusus Matkul Desain Algoritma**: Formulasi matematis TSP, relasi rekursi bitmask Held-Karp ($O(N^2 2^N)$), Nearest Neighbor ($O(N^2)$), 2-Opt, Dijkstra, dan analisis Big-O. |
| 📦 **[DSA_SPECIFICATION.md](docs/DSA_SPECIFICATION.md)** | **Khusus Matkul Struktur Data**: Teori `CargoStack` LIFO bagasi motor, `AdjacencyMatrix` ($O(1)$ memory lookup), dan `MinHeap` Priority Queue. |
| 🎨 **[design.md](design/design.md)** | Spesifikasi lengkap token desain, palet warna, tipografi, dan aset SVG. |

---

## 📂 Struktur Direktori Proyek

```text
KurirGO/
├── bin/
│   └── benchmark_tsp.dart       # CLI Benchmark pembanding Held-Karp vs Nearest Neighbor
│
├── design/                      # Aset SVG & spesifikasi desain Figma
│   ├── logo_kurirgo_app_icon.svg
│   ├── logo_kurirgo_horizontal.svg
│   ├── Frame_00_Login.svg
│   ├── Frame_00_Register.svg
│   ├── Frame_01_Dashboard.svg
│   ├── Frame_01_Dashboard_ProMax.svg
│   ├── Frame_02_VerifikasiMuatan.svg
│   ├── Frame_02_VerifikasiMuatan_ProMax.svg
│   ├── Frame_03_RuteGraph_Preview.svg
│   ├── Frame_03_RuteGraph_Preview_ProMax.svg
│   ├── Frame_04_LiveNavigation_InApp.svg
│   ├── Frame_04_LiveNavigation_ProMax.svg
│   ├── Frame_05_RiwayatPengantaran.svg
│   └── Frame_05_RiwayatPengantaran_ProMax.svg
│
├── docs/                        # Dokumentasi akademis & PRD
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── ALGORITHM_ANALYSIS.md
│   └── DSA_SPECIFICATION.md
│
├── lib/
│   ├── main.dart                # Entry point aplikasi Flutter
│   │
│   ├── core/                    # 🧠 LOGIKA AKADEMIS MURNI (Zero External Dependency)
│   │   ├── algorithms/          # Held-Karp DP, Nearest Neighbor, 2-Opt, Dijkstra
│   │   ├── dsa/                 # CargoStack (LIFO), AdjacencyMatrix, MinHeap, Graph
│   │   └── theme/               # Design Tokens (AppColors, AppTypography)
│   │
│   ├── data/
│   │   ├── models/              # WaypointModel, OrderModel, PaymentDetail
│   │   └── dummy_makassar_data.dart # Dataset koordinat riil Pettarani, Antang, Sudiang
│   │
│   └── features/                # 7 Layar Presentasi Flutter
│       ├── auth/                # Login (Screen 0A) & Register (Screen 0B)
│       ├── controllers/         # DeliveryController (ChangeNotifier)
│       ├── dashboard/           # Dashboard (Screen 1)
│       ├── load_verification/   # Verifikasi Muatan (Screen 2)
│       ├── route_preview/       # Preview Rute TSP (Screen 3)
│       ├── live_navigation/     # Navigasi & Kasir Multi-Metode (Screen 4)
│       └── history/             # Riwayat & Rekap Setoran Kasir (Screen 5)
│
└── test/                        # Pengujian Unit & Logika Algoritma
    ├── dsa_test.dart            # Test operasi LIFO, Matrix O(1), dan MinHeap
    └── algorithms_test.dart     # Test kebenaran Held-Karp vs Nearest Neighbor
```

---

## 🚀 Panduan Menjalankan Proyek

### 1. Prasyarat Lingkungan
- Flutter SDK `^3.47.0`
- Dart SDK `^3.13.7` (sesuai `pubspec.yaml`)
- Android Studio / VS Code dengan ekstensi Flutter & Dart

### 2. Mengambil Dependensi
```powershell
flutter pub get
```

### 3. Menjalankan Aplikasi Mobile
```powershell
flutter run
```

### 4. Menjalankan Pengujian Unit (Unit Tests)
Untuk memverifikasi kebenaran struktur data dan algoritma:
```powershell
flutter test test/dsa_test.dart
flutter test test/algorithms_test.dart
```

### 5. Menjalankan Benchmark Performa Algoritma (CLI Benchmark)
Untuk menguji waktu komputasi ($O(N^2)$ vs $O(N^2 2^N)$) dan mencetak tabel perbandingan untuk laporan tugas akhir:
```powershell
dart run bin/benchmark_tsp.dart
```

---

## 👥 Tim & Kolaborasi

- **Product Owner / Mahasiswa:** Nur Muhammad Ali
- **Product Design & Architecture Lead:** Antigravity (DeepMind)
- **Engineering & Implementation Lead:** Codex (OpenAI)
- **Studi Kasus:** Pengantaran Kue Brownies Browcyl — Makassar, Sulawesi Selatan


## Verifikasi Fase 4

```powershell
flutter test
flutter analyze
flutter build apk --debug
flutter test test/presentation_test.dart --dart-define=PREVIEW_DIR=design/previews
```

Akun demo lokal: ardiansyah / 1234.
Peta dasar memakai OpenStreetMap online, sedangkan geometri rute tersimpan lokal.
Gerakan kurir adalah simulasi 20x yang dikontrol lewat Putar, Jeda, dan Ulangi.
Tombol Google Maps membuka navigasi eksternal. Tidak ada izin GPS perangkat.

Jarak matriks TSP tetap 28,5 km. Geometri OSRM tersimpan sekitar 40,93 km;
HUD mengikuti jarak geometri tersebut. Inter dan lisensi OFL dibundel lokal.
Preview Flutter: design/previews/*_393.png dan *_320.png, termasuk teks 1,6x.
Tile pada widget test diganti gambar lokal, sehingga preview tidak menampilkan
peta dasar online. Pengujian tidak menghubungi pelanggan atau gateway pembayaran.

Untuk Android yang terhubung lewat USB debugging atau emulator:
flutter devices
flutter run -d <id-perangkat-android>

Hasil validasi terbaru: [PHASE4_VALIDATION.md](docs/PHASE4_VALIDATION.md).
Detail simulasi dan batas pengujiannya: [NAVIGATION_VALIDATION.md](docs/NAVIGATION_VALIDATION.md).

Adaptasi UI dari dokumen FigCraft: [FIGCRAFT_UI_VALIDATION.md](docs/FIGCRAFT_UI_VALIDATION.md).
Referensi lokal: `design/KurirGO_Final_UI.figcraft`. Dashboard menyediakan tab
Home/Performa/Profil; nama dan WhatsApp dapat diubah selama sesi aplikasi.
