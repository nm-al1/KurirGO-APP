# Analisis Desain Algoritma: Optimasi Rute Pengantaran Tertutup
## Kasus: Browcyl Delivery Makassar (Traveling Salesperson Problem with Closed-Loop Return)

- **Mata Kuliah:** Desain dan Analisis Algoritma (DAA)
- **Topik Kajian:** Traveling Salesperson Problem (TSP), Dynamic Programming (Held-Karp), Greedy Heuristic (Nearest Neighbor), Local Search (2-Opt), dan Dijkstra Shortest Path
- **Penyusun:** Tim Pengembang Browcyl Delivery (KurirGO)

---

## 1. Formulasi Masalah (Problem Formulation)

Dalam kasus pengantaran kurir Browcyl di kota Makassar, kurir memulai perjalanan dari satu titik pangkalan utama (**Depot Pettarani**, dinotasikan sebagai $V_0$), wajib mengantarkan seluruh pesanan boks kue ke sejumlah lokasi pelanggan/outlet ($V_1, V_2, \dots, V_{N-1}$), dan **wajib kembali ke Depot Pettarani ($V_0$)** untuk menyerahkan boks kosong dan menyetorkan uang tunai hasil transaksi COD.

Secara graf matematis:
Diberikan graf berarah dan berbobot lengkap $G = (V, E, W)$, dimana:
- $V = \{V_0, V_1, \dots, V_{N-1}\}$ adalah himpunan simpul lokasi ($|V| = N$).
- $E = \{(u, v) \mid u, v \in V, u \ne v\}$ adalah himpunan sisi rute perjalanan.
- $W: E \to \mathbb{R}^+$ adalah fungsi bobot yang menyatakan jarak geometris atau jarak jalan raya (dalam kilometer) antara simpul $u$ dan $v$, dinotasikan sebagai $D[u][v]$.

### Fungsi Tujuan (Objective Function):
Temukan permutasi urutan kunjungan simpul $\pi = (\pi(0), \pi(1), \dots, \pi(N-1))$ dengan kendala $\pi(0) = 0$ (dimulai dari Depot $V_0$) sedemikian rupa sehingga total jarak tempuh minimum:

$$\min_{\pi} \left[ \left( \sum_{i=0}^{N-2} D[V_{\pi(i)}][V_{\pi(i+1)}] \right) + D[V_{\pi(N-1)}][V_0] \right]$$

Masalah ini adalah kasus klasik **Traveling Salesperson Problem (TSP)** yang terbukti berada dalam kelas kompleksitas **NP-Hard**.

---

## 2. Pendekatan 1: Dynamic Programming (Algoritma Held-Karp)

### 2.1 Konsep dan Representasi Bitmask
Algoritma Held-Karp memecah masalah TSP menjadi sub-masalah tumpang tindih (*overlapping subproblems*) dengan prinsip optimalitas Bellman.

- **Representasi Himpunan Simpul Terkunjungi ($S$):** Menggunakan bilangan bulat (*bitmask*) berukuran $N$ bit.
  - Jika bit ke-$k$ bernilai 1, maka simpul $V_k$ telah dikunjungi.
  - Contoh untuk $N = 3$:
    - Mask `1` (`001` biner): Himpunan $\{V_0\}$
    - Mask `5` (`101` biner): Himpunan $\{V_0, V_2\}$
    - Mask `7` (`111` biner): Himpunan $\{V_0, V_1, V_2\}$ (seluruh simpul telah dikunjungi)

### 2.2 Relasi Rekursi (Recurrence Relation)
Definisikan $\text{cost}(S, u)$ sebagai jarak minimum untuk mengunjungi seluruh simpul dalam himpunan $S$, dimulai dari simpul 0 ($V_0$) dan berakhir tepat di simpul $u \in S$:

$$\text{cost}(S, u) = \min_{v \in S \setminus \{u\}} \left( \text{cost}(S \setminus \{u\}, v) + D[v][u] \right)$$

#### Kasus Dasar (Base Case):
$$\text{cost}(\{0\}, 0) = 0$$
$$\text{cost}(\{0\}, u) = \infty \quad \forall u \ne 0$$

#### Penyelesaian Siklus Tertutup (Closing the Loop):
Setelah seluruh simpul dikunjungi (mask bernilai $2^N - 1$), rute harus ditutup dengan kembali ke simpul asal ($V_0$):
$$\text{Optimal Tour Length} = \min_{u \in V \setminus \{0\}} \left( \text{cost}(\text{All}, u) + D[u][0] \right)$$

### 2.3 Pseudocode Held-Karp
```text
ALGORITHM HeldKarpTSP(D, N)
Input: Matriks Jarak D[N][N], Jumlah Simpul N
Output: Total Jarak Minimum dan Urutan Tour

1. Inisialisasi memo[1 << N][N] dengan nilai INFINITY
2. Inisialisasi parent[1 << N][N] dengan nilai -1
3. memo[1][0] = 0.0  // Base case: himpunan {0}, berakhir di 0

4. FOR mask FROM 1 TO (1 << N) - 1:
5.     IF (mask & 1) == 0 THEN CONTINUE // V0 wajib selalu ada
6.     FOR u FROM 0 TO N - 1:
7.         IF (mask & (1 << u)) == 0 THEN CONTINUE
8.         IF memo[mask][u] == INFINITY THEN CONTINUE
9.         FOR v FROM 0 TO N - 1:
10.            IF (mask & (1 << v)) != 0 THEN CONTINUE // v belum dikunjungi
11.            next_mask = mask | (1 << v)
12.            new_cost = memo[mask][u] + D[u][v]
13.            IF new_cost < memo[next_mask][v] THEN:
14.                memo[next_mask][v] = new_cost
15.                parent[next_mask][v] = u

16. all_visited = (1 << N) - 1
17. min_total_cost = INFINITY
18. last_node = -1
19. FOR u FROM 1 TO N - 1:
20.     total_cost = memo[all_visited][u] + D[u][0]
21.     IF total_cost < min_total_cost THEN:
22.         min_total_cost = total_cost
23.         last_node = u

24. // Rekonstruksi Jalur (Backtracking via parent)
25. tour = RekonstruksiTour(parent, all_visited, last_node, N)
26. RETURN (tour, min_total_cost)
```

### 2.4 Analisis Kompleksitas Held-Karp
- **Kompleksitas Waktu (Time Complexity):**
  Jumlah sub-masalah yang dihitung adalah perkalian jumlah kombinasi himpunan bagian ($2^N$) dengan simpul akhir ($N$). Untuk setiap state $(S, u)$, kita melakukan transisi ke $N$ simpul kandidat.
  $$\text{Time Complexity} = \sum_{k=1}^N \binom{N}{k} \cdot k \cdot (N - k) = O(N^2 \cdot 2^N)$$
  *Untuk $N = 3$:* $3^2 \cdot 2^3 = 9 \cdot 8 = 72$ operasi (berjalan dalam $< 1\text{ ms}$).
  *Untuk $N = 12$:* $144 \cdot 4096 \approx 5.8 \times 10^5$ operasi (berjalan dalam $\sim 50\text{ ms}$ di smartphone kurir).
- **Kompleksitas Ruang (Space Complexity):**
  Tabel memoisasi `memo` dan `parent` berukuran $2^N \times N$ entri float.
  $$\text{Space Complexity} = O(N \cdot 2^N)$$

---

## 3. Pendekatan 2: Greedy Heuristic (Nearest Neighbor Algorithm)

### 3.1 Konsep dan Mekanisme Keputusan
Algoritma Nearest Neighbor membuat keputusan lokal optimal pada setiap tahap: dari simpul aktif saat ini, kurir selalu memilih simpul terdekat berikutnya yang belum pernah dikunjungi.

### 3.2 Pseudocode Nearest Neighbor
```text
ALGORITHM NearestNeighborTSP(D, N, startNode)
Input: Matriks Jarak D[N][N], Jumlah Simpul N, Simpul Awal startNode (0)
Output: Tour Permutasi dan Total Jarak

1. visited = Array boolean berukuran N, inisialisasi FALSE
2. tour = List kosong
3. current = startNode
4. visited[current] = TRUE
5. tour.add(current)
6. total_distance = 0.0

7. WHILE tour.length < N:
8.     nearest_node = -1
9.     min_dist = INFINITY
10.    FOR v FROM 0 TO N - 1:
11.        IF NOT visited[v] AND D[current][v] < min_dist THEN:
12.            min_dist = D[current][v]
13.            nearest_node = v
14.    visited[nearest_node] = TRUE
15.    tour.add(nearest_node)
16.    total_distance = total_distance + min_dist
17.    current = nearest_node

18. // Tutup rute kembali ke simpul awal
19. total_distance = total_distance + D[current][startNode]
20. tour.add(startNode)
21. RETURN (tour, total_distance)
```

### 3.3 Analisis Kompleksitas Nearest Neighbor
- **Kompleksitas Waktu:** Terdapat $N$ iterasi simpul. Di setiap iterasi, dilakukan pemindaian linier $O(N)$ terhadap simpul-simpul yang tersisa.
  $$\text{Time Complexity} = O(N^2)$$
- **Kompleksitas Ruang:** Hanya membutuhkan array penanda `visited` berukuran $N$.
  $$\text{Space Complexity} = O(N)$$

### 3.4 Keterbatasan Greedy (Mengapa Bisa Terjebak Local Optima?)
Pendekatan rakus (*greedy*) tidak mempertimbangkan konsekuensi jarak pulang di akhir rute. Seringkali, simpul terakhir yang tersisa berada di ujung kota yang sangat jauh dari depot awal, mengakibatkan segmen penutup $D[\text{last}][0]$ bernilai sangat besar.
*Pada kasus Browcyl:* Nearest Neighbor dapat menghasilkan jarak hingga 15% - 20% lebih panjang dibanding rute optimal Held-Karp.

---

## 4. Pendekatan 3: 2-Opt Local Search Refinement

Untuk memperbaiki kelemahan algoritma Greedy tanpa beban komputasi eksponensial, diterapkan algoritma perbaikan lokal **2-Opt**.

### 4.1 Mekanisme 2-Opt Swap
Diberikan tour yang berisi sisi $(A, B)$ dan $(C, D)$ yang bersilangan. 2-Opt memutus kedua sisi tersebut dan menghubungkan kembali sebagai $(A, C)$ dan $(B, D)$ dengan cara membalikkan sub-rute antara $B$ dan $C$:

$$\Delta = (D[A][C] + D[B][D]) - (D[A][B] + D[C][D])$$
Rumus dua sisi di atas berlaku untuk matriks **simetris**. Pada graf berarah/asimetris, pembalikan sub-rute juga membalik seluruh sisi internal. Untuk indeks tour `i..j`, gunakan:

$$\Delta_{directed} = \Delta + \sum_{k=i}^{j-1} (D[t_{k+1}][t_k] - D[t_k][t_{k+1}])$$

Implementasi membangun prefix sum perubahan biaya internal setiap putaran agar setiap kandidat tetap dievaluasi dalam O(1). Evaluasi seluruh pasangan memerlukan O(N^2) per putaran dan pembalikan terpilih O(N), dengan ruang tambahan O(N). Pilih perbaikan terbaik dengan delta < -1e-9; berhenti ketika tidak ada kandidat yang memenuhi toleransi tersebut. Ini merupakan minimum lokal terhadap pembalikan segmen, bukan jaminan optimum global.

```text
Tour Awal    : V0 ➔ V1 ➔ V2 ➔ V0 (Bersilangan)
2-Opt Swap   : Balikkan urutan antara node 1 dan 2
Tour Hasil   : V0 ➔ V2 ➔ V1 ➔ V0 (Jalur Segitiga Mulus / Optimal)
```

- **Kompleksitas Waktu:** $O(N^2)$ per putaran evaluasi pasangan sisi.

---

## 5. Pendekatan 4: Dijkstra Shortest Path Router

Saat kurir sedang bergerak di lapangan (Screen 4 Live Navigation), algoritma Dijkstra digunakan untuk menghitung lintasan jalan riil terpendek dari posisi kurir ke persimpangan jalan tujuan.

### 5.1 Formulasi Relaksasi Sisi
Untuk setiap sisi $(u, v)$ dengan bobot jalan $w(u, v)$:
$$\text{IF } \text{dist}[v] > \text{dist}[u] + w(u, v) \text{ THEN } \text{dist}[v] = \text{dist}[u] + w(u, v)$$

Dengan menggunakan struktur data **Binary Min-Heap** (`lib/core/dsa/priority_queue.dart`), proses penarikan simpul berjarak minimum (`extractMin`) berjalan dalam $O(\log V)$, menghasilkan kompleksitas total:
$$\text{Time Complexity} = O((V + E) \log V)$$
$$\text{Space Complexity} = O(V)$$

---

## 6. Tabel Komparasi Menyeluruh (Untuk Bab Evaluasi Akademis)

| Parameter | Held-Karp DP | Nearest Neighbor (Greedy) | 2-Opt Local Search | Dijkstra Router |
| :--- | :--- | :--- | :--- | :--- |
| **Tujuan** | Optimasi Tour Tertutup | Heuristik Tour Cepat | Perbaikan Tour Greedy | Titik ke Titik (Point-to-Point) |
| **Karakteristik Solusi** | **Eksak Global Minimum** | Sub-optimal / Aproksimasi | Dekat Optimal | Optimal Point-to-Point |
| **Time Complexity** | $O(N^2 \cdot 2^N)$ | $O(N^2)$ | $O(k \cdot N^2)$ | $O((V+E)\log V)$ |
| **Space Complexity** | $O(N \cdot 2^N)$ | $O(N)$ | $O(N)$ | $O(V)$ |
| **Skalabilitas Praktis** | Efisien untuk $N \le 15$ | Sangat Cepat ($N > 10.000$) | Cepat ($N \le 1.000$) | Skala Peta Kota Besar |
| **Implementasi di Browcyl** | Core Routing Screen 3 | Baseline Komparasi CLI | Optimasi Jalur Cepat | Navigasi Realtime Screen 4 |

