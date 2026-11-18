# Product Requirement Document (PRD)
## Browcyl Delivery (KurirGO) — Intelligent Route Optimization & Cargo Management

- **Project Name:** Browcyl Delivery (KurirGO)
- **Target Platform:** Mobile (Android & iOS)
- **Tech Stack:** Flutter (Dart 3.x) — Pure Dart Core Algorithms
- **Academic Context:** Dual Course Project (Struktur Data & Desain Analisis Algoritma)
- **Design Reference:** Figma Design File `cLq6mInWmssvSCQuaviNpc` (*Browcyl Delivery - Final UI (Pro Max)*)
- **Author:** Antigravity (Product Design & Architecture Lead)
- **Engineering Partner:** Codex (Engineering & Implementation Lead)
- **Status:** Approved / Ready for Implementation

---

## 1. Executive Summary & Problem Statement

### 1.1 Latar Belakang Bisnis (Browcyl Makassar)
Browcyl adalah brand kuliner kue brownies ternama di Makassar dengan produk andalan seperti Brownies Kukus Unti, Choco Banana Melt, dan Bolu Klasik. Browcyl melayani pengantaran mandiri (*in-house courier delivery*) dari pusat distribusi (Depot Pettarani) ke berbagai cabang outlet dan pelanggan di kota Makassar (misal: Antang, Sudiang, Panakkukang).

### 1.2 Masalah Operasional Kurir
1. **Kesulitan Menentukan Rute Tercepat:** Kurir seringkali kebingungan menentukan urutan pengantaran saat membawa banyak box kue ke berbagai penjuru kota Makassar, menyebabkan jarak tempuh boros, waktu terbuang, dan bensin membengkak.
2. **Karakteristik Produk Rentan:** Kue brownies memiliki batas toleransi suhu dan guncangan. Berada terlalu lama di jalanan berdebu dan terik matahari Makassar dapat merusak tekstur dan lelehan cokelat.
3. **Kendala Bongkar Muat Fisik di Jalan:** Jika urutan peletakan barang di bagasi motor acak, kurir harus membongkar seluruh isi bagasi di pinggir jalan untuk mencari paket pelanggan pertama, meningkatkan risiko kotak kue penyok.
4. **Masalah Rekonsiliasi Kasir & Multi-Pembayaran:** Pelanggan membayar dengan metode beragam (COD tunai, QRIS, Transfer Bank, Cash). Tanpa pencatatan digital, kasir depot kesulitan merekonsiliasi uang fisik vs transfer saat kurir kembali.

### 1.3 Solusi Sistem
Aplikasi mobile kurir berbasis **Traveling Salesperson Problem (TSP) with Closed-Loop Return** yang secara cerdas:
- Memverifikasi muatan dengan struktur data **Stack LIFO** (Last In, First Out) agar susunan bagasi motor sesuai urutan rute.
- Menghitung rute tertutup terpendek (Depot $V_0 \to \text{Semua Titik} \to \text{Kembali ke Depot } V_0$) menggunakan **Dynamic Programming (Held-Karp)** dan **Greedy Heuristic (Nearest Neighbor)**.
- Menyediakan panduan navigasi jalan riil Makassar (*Turn-by-Turn GPS*).
- Mengelola multi-pembayaran (COD, QRIS, Transfer, Cash) dengan kalkulator kembalian otomatis dan rekap kasir.

---

## 2. User Personas & User Stories

### Persona 1: Ardiansyah (Kurir Motor Lapangan)
- **Profil:** Pengendara motor operasional Browcyl, mengantar kue di bawah cuaca panas Makassar dengan sarung tangan motor.
- **Kebutuhan:**
  - UI kontras tinggi yang terbaca jelas di bawah terik matahari (*outdoor high contrast*).
  - Tombol aksi besar ($\ge 54\text{ px}$) yang mudah ditekan dengan satu tangan.
  - Petunjuk langsung urutan pengantaran tanpa perlu menebak rute.
  - Kalkulator kembalian instan saat menerima uang tunai COD.

### Persona 2: Ibu Rahma (Kepala Gudang / Kasir Depot Pettarani)
- **Profil:** Mengelola stok box brownies dan rekonsiliasi setoran uang di Hub Pettarani.
- **Kebutuhan:**
  - Memastikan seluruh box kue fisik sudah diverifikasi sebelum kurir jalan.
  - Rekapitulasi setoran instan di akhir shift: membedakan uang kertas fisik yang harus disetor kurir vs pembayaran non-tunai (QRIS/Transfer).

---

## 3. Academic Framework (DSA & DAA)

Sebagai proyek gabungan dua mata kuliah inti informatika, **seluruh modul pada Section 3 wajib diimplementasikan murni menggunakan Pure Dart tanpa library eksternal** di folder `lib/core/`.

### 3.1 Mata Kuliah: Struktur Data (DSA)

```
┌─────────────────────────────────────────────────────────────┐
│                       DSA Core Models                       │
├─────────────────────┬───────────────────────────────────────┤
│ CargoStack<T>       │ LIFO Model untuk bagasi motor kurir   │
│ AdjacencyMatrix     │ 2D Matrix D[N][N] bobot jarak (O(1))  │
│ MinHeap<T>          │ Priority Queue untuk Dijkstra & SLA   │
│ DeliveryGraph       │ Graf Berarah Berbobot (V, E)          │
└─────────────────────┴───────────────────────────────────────┘
```

1. **`CargoStack<T>` (Stack LIFO - Last In First Out):**
   - *File:* `lib/core/dsa/cargo_stack.dart`
   - *Konsep:* Paket yang akan diantar di **Stop #1** harus ditaruh **paling terakhir** di bagasi motor (posisi tumpukan paling atas).
   - *Operasi:* `push(item)` saat loading di depot, `pop()` saat sampai di alamat tujuan, `peek()`, `isEmpty`, `length`.
   - *Kompleksitas:* $O(1)$ untuk semua operasi utama.

2. **`AdjacencyMatrix` (Matriks Ketetanggaan Berbobot):**
   - *File:* `lib/core/dsa/adjacency_matrix.dart`
   - *Konsep:* Tabel 2 dimensi $D[N][N]$ yang menyimpan jarak geometris / jalan raya antar simpul $u$ dan $v$.
   - *Operasi:* `setDistance(u, v, dist)`, `getDistance(u, v)`.
   - *Kompleksitas:* Lookup jarak antar dua titik instan $O(1)$, ruang $O(N^2)$.

3. **`MinHeap<T>` (Priority Queue berbasis Binary Heap):**
   - *File:* `lib/core/dsa/priority_queue.dart`
   - *Konsep:* Mengatur simpul berdasarkan bobot terkecil untuk Dijkstra serta antrian pesanan dengan SLA paling mendesak.
   - *Operasi:* `insert(element, priority)`, `extractMin()`, `peek()`.
   - *Kompleksitas:* $O(\log N)$ insert dan extract, $O(1)$ peek.

4. **`DeliveryGraph`:**
   - *File:* `lib/core/dsa/graph.dart`
   - *Konsep:* Menyimpan simpul $V_0, V_1, \dots, V_{N-1}$ dan koleksi sisi berarah (*directed edges*) dengan atribut jarak (KM) dan estimasi waktu (menit).

---

### 3.2 Mata Kuliah: Desain dan Analisis Algoritma (DAA)

Kasus utama adalah **Traveling Salesperson Problem (TSP) with Closed-Loop Constraint**:
$$\min \sum_{i=0}^{N-1} d(V_{\pi(i)}, V_{\pi(i+1)}) \quad \text{dimana } V_{\pi(0)} = V_{\pi(N)} = V_0$$

1. **Exact Dynamic Programming — Held-Karp Algorithm (Bitmask DP):**
   - *File:* `lib/core/algorithms/held_karp_tsp.dart`
   - *Formula Rekursi:*
     $$\text{cost}(S, u) = \min_{v \in S \setminus \{u\}} \left( \text{cost}(S \setminus \{u\}, v) + D[v][u] \right)$$
     *Basis:* $\text{cost}(\{0\}, 0) = 0$
     *Kembali ke Depot:* $\min_{u \ne 0} (\text{cost}(\text{All}, u) + D[u][0])$
   - *Kompleksitas Waktu:* $O(N^2 \cdot 2^N)$
   - *Kompleksitas Ruang:* $O(N \cdot 2^N)$
   - *Karakteristik:* Menjamin solusi **100% optimal / jarak minimum absolut**.

2. **Greedy Heuristic — Nearest Neighbor Algorithm (NNA):**
   - *File:* `lib/core/algorithms/nearest_neighbor_tsp.dart`
   - *Logika:* Dari simpul aktif, cari simpul belum dikunjungi dengan nilai $D[u][v]$ terkecil. Setelah semua dikunjungi, kembali ke $V_0$.
   - *Kompleksitas Waktu:* $O(N^2)$
   - *Kompleksitas Ruang:* $O(N)$
   - *Karakteristik:* Sangat cepat, namun rentan *sub-optimal* (segmen pulang ke depot bisa sangat panjang).

3. **Local Search Refinement — 2-Opt Optimizer:**
   - *File:* `lib/core/algorithms/two_opt_optimizer.dart`
   - *Logika:* Mengambil tour hasil Greedy, lalu secara iteratif membalikkan sub-rute jika $d(A, C) + d(B, D) < d(A, B) + d(C, D)$ untuk menghilangkan garis rute bersilangan.
   - *Kompleksitas Waktu:* $O(N^2)$ per iterasi.

4. **Point-to-Point Pathfinder — Dijkstra Router:**
   - *File:* `lib/core/algorithms/dijkstra_router.dart`
   - *Logika:* Menghitung rute terpendek antar dua persimpangan jalan di grid peta Makassar menggunakan `MinHeap`.
   - *Kompleksitas:* $O((V + E) \log V)$.

---

### 3.3 Matriks Perbandingan Teoretis (Untuk Laporan Kuliah)

| Algoritma | Paradigma | Time Complexity | Space Complexity | Kualitas Solusi |
| :--- | :--- | :--- | :--- | :--- |
| **Held-Karp** | Dynamic Programming | $O(N^2 \cdot 2^N)$ | $O(N \cdot 2^N)$ | **Eksak Optimal (100%)** |
| **Nearest Neighbor** | Greedy Heuristic | $O(N^2)$ | $O(N)$ | Sub-optimal (Aproksimasi) |
| **Nearest Neighbor + 2-Opt** | Local Search | $O(k \cdot N^2)$ | $O(N)$ | Mendekati Optimal |
| **Dijkstra** | Greedy (Min-Heap) | $O((V+E)\log V)$ | $O(V)$ | Optimal (Point-to-Point) |

---

## 4. Functional Requirements (FR)

### FR-01: Kurir Authentication & Profile Initialization
- **Registrasi Akun Mandiri (Self-Registration):** Kurir baru mendaftar dengan membuat **Username sendiri** (misal: `ardiansyah`), Nama Lengkap, PIN 4-6 digit, dan pemilihan Hub Pangkalan (`Hub Pettarani`, `Hub Perintis`, `Hub Antang`). Nomor WhatsApp bersifat opsional untuk pemulihan/OTP. Bebas dari upload berkas sensitif PII (tanpa upload SIM C/KTP).
- **Masuk Akun (Login):** Kurir masuk menggunakan Username + PIN Akses.
- **Inisialisasi Tugas:** Sistem menampilkan profil kurir aktif: **Ardiansyah (Kurir Browcyl 5 Thn)** di **Hub Pettarani • Makassar** beserta ringkasan tugas: Total 5 Box Kue, 2 Alamat Pengantaran, Rute Loop Tertutup.

### FR-02: Cargo Verification & LIFO Stacking Validation
- Sistem menampilkan daftar pesanan:
  - `BRW-01`: 3 Box (Unti & Cokelat Klasik) ➔ Outlet Sudiang ($V_1$).
  - `BRW-02`: 2 Box (Choco Banana Melt) ➔ Outlet Antang ($V_2$).
- Kurir wajib mencentang checkbox verifikasi fisik box di bagasi motor.
- **Validasi LIFO:** Sistem memvalidasi urutan bongkar muat. Jika masih ada box belum dicentang, tombol rute dinonaktifkan dengan banner peringatan warna merah/amber.

### FR-03: Closed-Loop TSP Route Calculation
- Setelah muatan terverifikasi, sistem mengeksekusi solver TSP.
- Sistem mengurutkan titik pengantaran optimal:
  $$\text{Depot Pettarani } (V_0) \to \text{Stop \#1: Outlet Antang } (V_2) \to \text{Stop \#2: Outlet Sudiang } (V_1) \to \text{Kembali ke Depot } (V_0)$$
- Menampilkan metrik: Total jarak **28.5 KM**, estimasi **1 Jam 10 Mnt**, dan efisiensi **-32% BBM**.

### FR-04: Visual Graph & Matrix Representation
- Menampilkan visualisasi graf peta dengan simpul $V_0, V_1, V_2$ dan garis trajektori berbobot jarak (8.2 KM, 12.3 KM, 8.0 KM).
- Tab navigasi segmented: `[ Urutan Rute Loop (TSP) ]` dan `[ Detail Jarak (KM) ]`.
- Tab Detail Jarak menampilkan representasi tabel Adjacency Matrix $D[N][N]$.

### FR-05: Real-time In-App GPS Navigation
- Menampilkan HUD Turn-by-Turn mengambang di atas peta:
  - Jarak ke belokan: `500 M`.
  - Instruksi: `Belok Kanan ke Jl. Antang Raya No. 45`.
  - Telemetri GPS: `Akurasi ±3m • Kecepatan 38 km/h`.
- Marker posisi kurir (*GPS Puck*) dengan radar pulsa dan arah hadap (*heading arrow*).
- Rambu batas kecepatan: `40 km/h`.

### FR-06: Multi-Channel Payment & Quick Cash Calculator
- Mendukung 4 metode pembayaran:
  1. **COD (Cash on Delivery):** Menampilkan nominal tagihan Rp 150.000 dengan kalkulator uang kembalian cepat (*Quick Change*).
  2. **Cash Tunai:** Serupa COD untuk transaksi di tempat.
  3. **QRIS:** Tombol pop-up barcode QRIS dinamis/statis untuk di-scan pelanggan.
  4. **Transfer Bank:** Status verifikasi pembayaran transfer via BCA/Mandiri.
- Tombol toggle status pembayaran lunas (iOS style toggle switch).

### FR-07: Dynamic Re-routing (Skip / Fail Point)
- Jika pelanggan di Antang tidak berada di tempat, kurir dapat menekan tombol `Lewati Titik Ini`.
- Solver TSP secara dinamis menghitung ulang rute dari posisi koordinat sekarang ke titik berikutnya tanpa memasukkan simpul yang dilewati.

### FR-08: Shift Settlement & Reconciliation Report
- Saat tiba kembali di Depot Pettarani ($V_0$), sistem menampilkan ringkasan kas:
  - Uang Fisik Tunai (Wajib setor ke kasir depot).
  - Pembayaran Non-Tunai (QRIS & Transfer).
  - Total riwayat penghematan jarak dan BBM.

---

## 5. Non-Functional Requirements (NFR)

- **NFR-01 (Algorithm Performance):** Eksekusi algoritma TSP Held-Karp pada $N \le 15$ simpul harus selesai dalam waktu kurang dari **1000 milidetik** ($< 1\text{ detik}$) di perangkat mobile.
- **NFR-02 (Outdoor Ergonomics & Contrast):** Menggunakan palet kontras tinggi Matte Charcoal (`#18181B`) dan Electric Lime (`#C6FF00`) dengan rasio kontras $\ge 14.5:1$. Seluruh tombol utama memiliki tinggi minimal **54 px** untuk operasional satu tangan dengan sarung tangan.
- **NFR-03 (Offline Resiliency):** Data graf jalan, koordinat outlet, dan matriks jarak tersimpan di memori lokal (*in-memory*), sehingga navigasi rute tetap berjalan normal jika koneksi internet terputus di jalanan Makassar.
- **NFR-04 (Zero AI Slop / Professional Asset Standard):** Seluruh elemen visual berupa vektor geometri murni (tanpa emoji generik). Tipografi menggunakan Inter dengan hierarki tegas.

---

## 6. Data Contracts & Domain Models (Dart Specifications)

Kontrak Fase 3 mengikuti keputusan terbaru pengguna. Indeks node selalu V0=0, V1=1, V2=2; urutan kunjungan disimpan terpisah dari urutan daftar waypoint.

### waypoint_model.dart

```dart
class WaypointModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int nodeIndex;

  const WaypointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.nodeIndex,
  });

  bool get isDepot => nodeIndex == 0;
}
```

### payment_model.dart

```dart
import 'dart:math';

enum PaymentMethod { cod, cash, qris, transfer }

enum PaymentStatus { pending, paid, verified }

class PaymentDetail {
  final double nominalTagihan;
  final double? nominalDiterima;
  final PaymentMethod metode;
  PaymentStatus status;
  final String? referensiTransaksi;

  PaymentDetail({
    required this.nominalTagihan,
    required this.metode,
    this.nominalDiterima,
    this.status = PaymentStatus.pending,
    this.referensiTransaksi,
  }) {
    for (final value in [nominalTagihan, nominalDiterima]) {
      if (value != null && (!value.isFinite || value < 0)) {
        throw ArgumentError.value(
          value,
          'nominal',
          'Must be finite and nonnegative',
        );
      }
    }
  }

  double get uangKembalian =>
      metode == PaymentMethod.cash || metode == PaymentMethod.cod
      ? max(0.0, (nominalDiterima ?? 0) - nominalTagihan)
      : 0.0;
}
```

### order_model.dart

```dart
import 'payment_model.dart';

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String itemsDescription;
  final int boxCount;
  final double totalPrice;
  final int waypointIndex;
  bool isVerified;
  PaymentDetail payment;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.itemsDescription,
    required this.boxCount,
    required this.totalPrice,
    required this.waypointIndex,
    required this.payment,
    this.isVerified = false,
  });
}
```

### Fixture Makassar (`DummyMakassarData`)

Data identitas dan pesanan disepakati pengguna. Koordinat dan jarak merupakan fixture proyek; jarak belum diverifikasi melalui pengukuran jalan.

| Node | Nama | Koordinat | Alamat |
| --- | --- | --- | --- |
| V0 | Hub Depot Pettarani | -5.1560, 119.4350 | Jl. A.P. Pettarani No. 10 |
| V1 | Outlet Sudiang | -5.0782, 119.5215 | Jl. Perintis Kemerdekaan KM 18 No. 88, Sudiang, Makassar |
| V2 | Outlet Antang | -5.1685, 119.4820 | Jl. Antang Raya No. 45, Antang, Makassar |

Matriks berarah (KM), baris/kolom berurutan V0, V1, V2:

$$D = \begin{pmatrix} 0 & 16.5 & 8.2 \\ 8.0 & 0 & 12.3 \\ 8.2 & 12.3 & 0 \end{pmatrix}$$

Loop optimal: V0 -> V2 -> V1 -> V0, total 8.2 + 12.3 + 8.0 = 28.5 km. Matriks simetris dalam contoh DSA/test akademis adalah fixture terpisah (37 km).

| Pesanan | Pelanggan / Kontak | Isi | Tujuan | Tagihan | Pembayaran awal |
| --- | --- | --- | --- | --- | --- |
| BRW-01 | Bpk. Rahmat (Outlet Sudiang), 0811-4455-6677 | 3 Box (Unti Kelapa & Brownies Cokelat) | V1, Stop #2 | Rp225.000 | QRIS, paid; Transfer juga diizinkan |
| BRW-02 | Ibu Nurul (Outlet Antang), 0812-9988-7766 | 2 Box (Choco Banana Melt) | V2, Stop #1 | Rp150.000 | COD tunai, pending |

`waypoints` immutable; `createOrders()` dan `createDistanceMatrix()` menghasilkan objek baru setiap panggilan. Verifikasi bagasi kedua pesanan dimulai false, terpisah dari status pembayaran. Penerimaan uang dan referensi transaksi awal null. Untuk mengubah nominal/metode pembayaran, ganti objek `order.payment`; status pembayaran dapat diperbarui langsung.

---

## 7. UI/UX Design System & Screen Specifications

Desain merujuk pada file Figma: `cLq6mInWmssvSCQuaviNpc` dan token di `lib/core/theme/app_colors.dart`.

### 7.1 Design Tokens
- `AppColors.electricLime` (`#C6FF00`): Aksen utama, kontras tinggi di bawah matahari.
- `AppColors.matteCharcoal` (`#18181B`): Latar belakang gelap, kartu hero, bottom sheet.
- `AppColors.darkSecondary` (`#27272A`): Kartu elevasi, badge latar.
- `AppColors.backgroundLight` (`#F8FAFC`): Canvas background terang.
- `AppColors.borderLight` (`#E2E8F0`): Garis pembatas kartu.
- `AppColors.statusGreen` (`#10B981`): Status lunas & GPS lock.
- `AppColors.statusAmber` (`#F59E0B`): Banner peringatan muatan.
- `AppColors.statusRed` (`#EF4444`): Indikator belum diverifikasi & speed limit.

### 7.2 Spesifikasi 4 Layar Utama
1. **Screen 1 (`DashboardScreen`):**
   - Path: `lib/features/dashboard/dashboard_screen.dart`
   - Header profil kurir (Ardiansyah), status bar Dynamic Island, 5G & GPS indicator.
   - Hero card warna Charcoal dengan rute graf gelombang hijau lime.
   - List pesanan (`BRW-01` dan `BRW-02`) dengan ilustrasi isometrik boks 3D.
   - Floating ergonomic dock (Home, Map, Analytics, Profile).
   - Tombol aksi utama (CTA): *"Cek Muatan Barang"* (54px height, full pill).

2. **Screen 2 (`LoadVerificationScreen`):**
   - Path: `lib/features/load_verification/load_verification_screen.dart`
   - Dark top header: *"Verifikasi Muatan Box"* & total 5 box.
   - Bottom sheet putih melengkung dengan drag handle.
   - Notice banner inspeksi fisik bagasi kurir (ikon shield vektor).
   - Card pesanan dengan state interaktif:
     - `BRW-01` (Checked): Background Charcoal, checkmark neon lime.
     - `BRW-02` (Unchecked): Background putih, checkbox border abu-abu.
   - Alert banner merah: *"1 Pesanan Belum Terverifikasi"*.
   - Kartu penjelasan algoritma TSP.
   - Tombol aksi utama (CTA): *"Urutkan Rute Loop (TSP)"*.

3. **Screen 3 (`RoutePreviewScreen`):**
   - Path: `lib/features/route_preview/route_preview_screen.dart`
   - Canvas peta arteri Makassar (Jl. Pettarani, Jl. Perintis, Jl. Antang Raya).
   - Graf rute tertutup segitiga menyala (`#C6FF00`) dengan badge jarak tiap koridor.
   - Simpul $V_0$ berpendar dengan ikon depot, simpul $V_2$ (#1) dan $V_1$ (#2).
   - Top floating pill: *"28.5 KM (Full Loop) • 1 Jam 10 Mnt • -32% BBM"*.
   - Segmented control tab: `Urutan Rute Loop (TSP)` vs `Detail Jarak (KM)`.
   - Timeline urutan perjalanan lengkap.
   - Tombol aksi utama (CTA): *"Mulai Navigasi Langsung"*.

4. **Screen 4 (`LiveNavigationScreen`):**
   - Path: `lib/features/live_navigation/live_navigation_screen.dart`
   - Top HUD Turn Banner Charcoal: Panah belok kanan hijau lime tebal, jarak `500 M`, petunjuk `Belok Kanan ke Jl. Antang Raya No. 45`, GPS telemetri (±3m, 38 km/h).
   - Rambu batas kecepatan `40 km/h` dan tombol kompas/recenter.
   - Map road traversal dengan trajektori berpendar dan GPS puck kurir.
   - Bottom interaction console: Profil pelanggan Ibu Nurul, tombol call & WA.
   - Selector metode pembayaran (COD, Cash, QRIS, Transfer) dan kalkulator kembalian.
   - Toggle switch status pembayaran lunas.
   - Tombol aksi utama (CTA): *"Selesaikan & Lanjut ke Stop #2 (Sudiang)"*.

---

## 8. Benchmark CLI Specification (`bin/benchmark_tsp.dart`)

Jalankan `dart run bin/benchmark_tsp.dart`. Tabel membandingkan Held-Karp dan Nearest Neighbor untuk N=3,6,10,12. N=3 memakai fixture Makassar; ukuran lain memakai graf berarah sintetis dengan `Random(42 + N)` dan bobot antarsimpul integer 1..30 km.

Setiap solver memakai satu warm-up dan lima sampel pada matriks yang sama. Runtime adalah median `executionTime` dalam mikrodetik, termasuk validasi input solver. Runtime dipengaruhi Dart JIT dan mesin lokal; angka bukan patokan perangkat mobile.

Kolom: N, HK (us), NN (us), HK (km), NN (km), Est. BBM (%). Estimasi dihitung `(jarakNN - jarakHK) / jarakNN * 100`, atau nol jika jarakNN nol. Ini proksi penghematan berbasis jarak dengan asumsi konsumsi per km konstan, bukan hasil pengukuran BBM. Pada N=3 kedua solver menghasilkan 28.5 km dan estimasi penghematan 0%. Semua nilai runtime/jarak dicetak dari eksekusi aktual.

---

## 9. Definition of Done (DoD) & Acceptance Criteria for Codex

Sebuah fitur atau modul dinyatakan **DONE** jika memenuhi kriteria berikut:
1. **Core DSA & DAA:**
   - [ ] Seluruh class struktur data (`CargoStack`, `AdjacencyMatrix`, `MinHeap`, `DeliveryGraph`) terimplementasi tanpa error.
   - [ ] Algoritma TSP Held-Karp dan Nearest Neighbor mengembalikan rute valid tertutup ($V_0 \to \dots \to V_0$).
   - [ ] Seluruh unit test di `test/dsa_test.dart` dan `test/algorithms_test.dart` lolos (`flutter test` exit code 0).
2. **Benchmark:**
   - [ ] Script `bin/benchmark_tsp.dart` dapat dieksekusi dengan `dart run` dan mencetak tabel perbandingan rapi.
3. **UI / Flutter Screens:**
   - [ ] 4 Layar (Dashboard, Verifikasi, Route Preview, Live Navigation) terpasang dengan tema warna Electric Lime (`#C6FF00`) dan Charcoal (`#18181B`).
   - [ ] Interaksi tombol checklist muatan, perpindahan layar, dan toggle pembayaran berfungsi interaktif.
   - [ ] `flutter analyze` bersih tanpa warning berat.
4. **Knowledge Graph Sync:**
   - [ ] Menjalankan `codegraph sync .` setelah implementasi agar graph proyek tetap up-to-date.



## Phase 4 — Final operational flow

Login/register -> Dashboard -> Verifikasi -> Preview Rute -> Navigasi -> Riwayat.
Auth is a local session demo (ardiansyah / 1234); registration has name, username,
optional WhatsApp, PIN/confirmation and SOP agreement. No SIM C or motor plate.
The route always uses Pettarani as its depot. No account server or persistence.

Verify both orders before solving TSP. The bag is loaded Sudiang first, Antang
last; each completed delivery pops its order. Simulation displays each customer's
address and allows COD, Tunai (automatic change), QRIS mock or Transfer manual
confirmation. Sudiang starts paid by QRIS. Never collect it again unless the
courier explicitly selects a different method. Call/Chat/Google Maps open external
apps only on a user action; failed launches provide a copy fallback.

After the second delivery, history shows the pending return to depot. The
Setor Tunai ke Kasir Depot action confirms arrival and cash handover, closes
the loop, then returns to dashboard. Mulai Rute Baru loads fresh fixture orders
while retaining the courier identity. Completed history remains until a new route.

Summary uses completed bills, excluding returned change: initial fixture gives
Rp150.000 cash, Rp225.000 noncash, Rp375.000 omzet. Changing payment methods
changes those totals. Metrics: Boks Terantar (5 Box / 100%), Total Jarak (28.5 KM),
Waktu Tempuh (1 Jam 10 Mnt, fixture estimate). Use Riwayat Pengantaran and
2 Pesanan Selesai; no shift jargon. GPS/HUD/QRIS are labeled simulation; the old
-32% BBM is replaced by the actual solver distance comparison (0% here).
