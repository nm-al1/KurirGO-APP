# Spesifikasi Struktur Data (DSA Specification)
## Implementasi Struktur Data Murni pada Sistem Kurir Browcyl Delivery

- **Mata Kuliah:** Struktur Data (DSA)
- **Fokus Kajian:** Stack LIFO (Bagasi Motor), Adjacency Matrix D[N][N], Binary Min-Heap (Priority Queue), dan Directed Weighted Graph
- **Penyusun:** Tim Pengembang Browcyl Delivery (KurirGO)

---

## 1. Pemetaan Struktur Data ke Masalah Nyata

Banyak aplikasi kurir gagal mempertimbangkan keterbatasan fisik lapangan. Pada proyek **Browcyl Delivery**, struktur data yang dipilih memiliki korelasi langsung antara **teori komputasi di memori (RAM)** dan **kondisi fisik operasional kurir di jalanan**:

```
┌─────────────────────────────────────────────────────────────────┐
│              PEMETAAN STRUKTUR DATA KE KONDISI FISIK            │
├───────────────────────┬─────────────────────────────────────────┤
│ STRUKTUR DATA KOMPUTER│ REALITAS FISIK OPERASIONAL BROWCYL      │
├───────────────────────┼─────────────────────────────────────────┤
│ 1. Stack (LIFO)       │ Susunan Boks Kue di Dalam Bagasi Motor   │
│ 2. Adjacency Matrix   │ Lookup Cepat Jarak & Waktu Antar Cabang │
│ 3. Binary Min-Heap    │ Antrian Pesanan SLA Darurat & Dijkstra  │
│ 4. Directed Graph     │ Jaringan Jalan Satu Arah Kota Makassar  │
└───────────────────────┴─────────────────────────────────────────┘
```

---

## 2. Struktur Data 1: `CargoStack<T>` (Stack LIFO untuk Bagasi Motor)

### 2.1 Latar Belakang Masalah Fisik
Bagasi motor kurir Browcyl memiliki bukaan atas (*top-loading compartment*). Boks brownies yang dimasukkan pertama kali akan berada di posisi paling dasar bagasi.

Jika sistem menggunakan struktur data **Queue (FIFO)**:
- Pesanan pertama (Stop #1) berada di dasar bagasi.
- Kurir harus membongkar seluruh 5 boks kue ke trotoar jalan untuk mengambil boks Stop #1.
- *Risiko:* Kotak brownies penyok, topping lumer kena panas matahari, dan waktu kurir terbuang.

### 2.2 Solusi Struktur Data: Stack LIFO
Dengan **Stack (Last In, First Out)**:
- Urutan loading boks di depot adalah kebalikan dari urutan rute pengantaran:
  1. `push(Stop #2 - Sudiang)` ➔ Masuk paling dasar bagasi.
  2. `push(Stop #1 - Antang)` ➔ Masuk paling atas bagasi (*Top of Stack*).
- Saat tiba di Outlet Antang (Stop #1), kurir cukup melakukan operasi `pop()`. Boks yang diambil langsung berada di tumpukan teratas tanpa perlu membongkar isi bagasi!

```
      BAGASI MOTOR KURIR                   REPRESENTASI MEMORI STACK
 ┌──────────────────────────┐             ┌──────────────────────────┐
 │ [TOP] Stop #1: Antang    │ ◄── POP()   │ index 1: Order BRW-02    │ ◄── Top Pointer
 ├──────────────────────────┤             ├──────────────────────────┤
 │ [BASE] Stop #2: Sudiang  │             │ index 0: Order BRW-01    │
 └──────────────────────────┘             └──────────────────────────┘
```

### 2.3 Pembuktian Kompleksitas Operasi `CargoStack`
Implementasi menggunakan internal array dinamis yang dikunci pada ujung akhir (*tail*):
- **`push(item)`**: Menambahkan elemen ke akhir array. Karena kapasitas dialokasikan secara berurutan, kompleksitas adalah $O(1)$ amortized.
- **`pop()`**: Menghapus elemen terakhir dari array tanpa perlu menggeser (*shift*) elemen lain. Kompleksitas $O(1)$.
- **`peek()`**: Mengakses elemen `_storage.last` melalui indeks langsung $O(1)$.
- **`isEmpty` & `length`**: Evaluasi ukuran array dalam $O(1)$.

---

## 3. Struktur Data 2: `AdjacencyMatrix` (Matriks Ketetanggaan $D[N][N]$)

### 3.1 Representasi Memori
Untuk merepresentasikan graf jarak antar simpul pengantaran Browcyl di Makassar:
- $V_0$: Hub Depot Pettarani
- $V_1$: Outlet Sudiang
- $V_2$: Outlet Antang

Data disimpan dalam array 2 dimensi berukuran $N \times N$:

$$D = \begin{pmatrix} 
0.0 & 16.5 & 8.2 \\ 
16.5 & 0.0 & 12.3 \\ 
8.2 & 12.3 & 0.0 
\end{pmatrix}$$

### 3.2 Analisis Memori & Efisiensi Lookup $O(1)$
Dalam memori komputer (RAM), array 2D disimpan secara linier (*Row-Major Order*). Untuk mengakses jarak dari simpul $u$ ke simpul $v$:
$$\text{Memory Address}(u, v) = \text{Base Address} + (u \times N + v) \times \text{SizeOf}(\text{double})$$

Karena alamat memori dapat dihitung langsung dengan operasi aritmetika dasar:
- **Kompleksitas Akses:** Tepat **$O(1)$ waktu konstan**!
- Ini adalah faktor kunci mengapa algoritma **Held-Karp Dynamic Programming** dapat berjalan sangat cepat, karena jutaan query jarak $D[u][v]$ selama proses rekursi bitmask dieksekusi instan tanpa pencarian linier.

### 3.3 Komparasi: Adjacency Matrix vs Adjacency List
Dalam masalah TSP, graf yang dihadapi adalah **Graf Lengkap (Complete Dense Graph)**, di mana setiap titik memiliki jalur ke semua titik lain ($|E| = N(N-1)$).

| Parameter | Adjacency Matrix (Pilihan Kita) | Adjacency List |
| :--- | :--- | :--- |
| **Lookup Jarak $D[u][v]$** | **$O(1)$ instan** | $O(\text{degree}(u)) = O(N)$ |
| **Konsumsi Ruang (RAM)** | $O(N^2)$ | $O(V + E) = O(N^2)$ pada graf lengkap |
| **Overhead Pointer** | **Nol (Array Primitif)** | Tinggi (Banyak object `Node` & `Edge`) |
| **Kesesuaian untuk TSP** | **Sangat Sempurna** | Kurang Efisien |

---

## 4. Struktur Data 3: `MinHeap<T>` (Binary Priority Queue)

### 4.1 Pemetaan Pohon Biner Lengkap ke Array 1D
`MinHeap` memodelkan pohon biner lengkap (*Complete Binary Tree*) tanpa menggunakan node berpointer, melainkan dipetakan langsung ke dalam indeks array 1 dimensi:

```
               [ 8.2 km ]  (Index 0)
              /          \
      [ 12.3 km ]      [ 16.5 km ]
       (Index 1)        (Index 2)
```

Rumus navigasi indeks pada array:
- **Parent dari node $i$:** $\text{parent}(i) = \lfloor (i - 1) / 2 \rfloor$
- **Left Child dari node $i$:** $\text{left}(i) = 2i + 1$
- **Right Child dari node $i$:** $\text{right}(i) = 2i + 2$

### 4.2 Properti Heap (Heap Property)
Untuk setiap simpul $i$ selain root:
$$\text{priority}(\text{parent}(i)) \le \text{priority}(i)$$
Artinya, elemen dengan jarak atau waktu paling minimum selalu berada di puncak heap (indeks 0).

### 4.3 Analisis Kompleksitas Operasi `MinHeap`
1. **`insert(element, priority)` (Heapify Up):**
   Elemen baru ditambahkan di akhir array, lalu dibandingkan dengan parent-nya dan ditukar ke atas jika prioritasnya lebih kecil.
   - Tinggi pohon biner dengan $N$ elemen adalah $\lfloor \log_2 N \rfloor$.
   - Maksimum pertukaran adalah ketinggian pohon ➔ **$O(\log N)$**.
2. **`extractMin()` (Heapify Down):**
   Elemen root (indeks 0) diambil, elemen terakhir array dipindahkan ke indeks 0, lalu ditukar ke bawah dengan child terkecilnya hingga properti heap kembali valid.
   - Maksimum pergeseran adalah ketinggian pohon ➔ **$O(\log N)$**.
3. **`peek()`:** Mengambil data pada indeks 0 tanpa menghapus ➔ **$O(1)$**.

---

## 5. Ringkasan Evaluasi untuk Dosen Struktur Data

Seluruh struktur data yang diimplementasikan pada proyek **Browcyl Delivery (KurirGO)**:
1. **Dibuat Murni (*From Scratch*)**: Ditulis di `lib/core/dsa/` tanpa memanggil library bawaan `dart:collection` Heap atau paket eksternal, sehingga membuktikan pemahaman konseptual mahasiswa.
2. **Berorientasi Efisiensi**: Operasi-operasi kritis berada pada batas teoritis terendah ($O(1)$ untuk Stack & Matrix, $O(\log N)$ untuk Heap).
3. **Kontekstual**: Menyelesaikan masalah fisik bagasi kurir motor roda dua di kota Makassar secara nyata.

