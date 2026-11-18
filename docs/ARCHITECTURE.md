# Technical Architecture Document
## Browcyl Delivery (KurirGO) — Intelligent Route Optimization & Cargo Management

- **Target Audience:** Codex (Engineering Lead), System Architects, Course Evaluators
- **Technology Stack:** Flutter (Dart 3.x) — Android & iOS Mobile
- **Design Reference:** Figma Design `cLq6mInWmssvSCQuaviNpc`
- **Specification Source:** `docs/PRD.md` and `design/design.md`

---

## 1. Architectural Philosophy & Layering

Aplikasi **KurirGO** mengadopsi arsitektur **Feature-First Clean Architecture** yang memisahkan ranah akademis (*Pure DSA & DAA*) dari framework antarmuka (*Flutter Presentation*).

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (Flutter)                 │
│   • DashboardScreen           • LoadVerificationScreen          │
│   • RoutePreviewScreen        • LiveNavigationScreen            │
│   Theme: AppColors (#18181B & #C6FF00), AppTypography (Inter)   │
├─────────────────────────────────────────────────────────────────┤
│                     State & Orchestration Layer                 │
│   • DeliveryController (ChangeNotifier)                         │
│   Manages: Cargo verification state, Active tour, Payment state │
├─────────────────────────────────────────────────────────────────┤
│                       Domain & Data Layer                       │
│   • WaypointModel     • OrderModel       • PaymentDetail        │
│   • DummyMakassarData (Pettarani V0, Sudiang V1, Antang V2)     │
├─────────────────────────────────────────────────────────────────┤
│             CORE ACADEMIC ENGINE (Pure Dart - Zero Dep)         │
│  ┌───────────────────────────────┬────────────────────────────┐ │
│  │   Struktur Data (DSA)         │   Desain Algoritma (DAA)   │ │
│  │   • CargoStack<T> (LIFO)      │   • HeldKarpTSP (DP)       │ │
│  │   • AdjacencyMatrix D[N][N]   │   • NearestNeighbor (NNA)  │ │
│  │   • MinHeap<T> (PriorityQueue)│   • TwoOptOptimizer (Local)│ │
│  │   • DeliveryGraph             │   • DijkstraRouter         │ │
│  └───────────────────────────────┴────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Golden Rules untuk Codex:
1. **Zero External Dependency di `lib/core/`**: Folder `lib/core/dsa/` dan `lib/core/algorithms/` hanya boleh mengimpor library bawaan Dart (`dart:math`, `dart:collection`, `dart:core`). Tidak boleh ada ketergantungan pada Flutter UI atau paket pub external.
2. **Deterministic & Testable**: Seluruh algoritma dan struktur data harus deterministik dan memiliki unit test mandiri di `test/`.
3. **Unidirectional Data Flow**: State aplikasi mengalir satu arah: *User Action ➔ Controller Method ➔ State Mutation ➔ `notifyListeners()` ➔ Widget Rebuild*.

---

## 2. Directory Structure & File Manifest

```text
lib/
├── main.dart                          # Application entry point & MaterialApp configuration
│
├── core/
│   ├── algorithms/                    # Pure Dart DAA Module
│   │   ├── tsp_solver.dart            # Abstract TSPSolver interface & TSPResult model
│   │   ├── held_karp_tsp.dart         # Exact O(N^2 * 2^N) Dynamic Programming
│   │   ├── nearest_neighbor_tsp.dart  # O(N^2) Greedy Heuristic
│   │   ├── two_opt_optimizer.dart     # O(N^2) Local Search 2-Opt refinement
│   │   └── dijkstra_router.dart       # O((V + E) log V) Shortest path using MinHeap
│   │
│   ├── dsa/                           # Pure Dart DSA Module
│   │   ├── cargo_stack.dart           # Generic LIFO Stack with verification guards
│   │   ├── adjacency_matrix.dart      # 2D weighted matrix D[N][N] with O(1) lookups
│   │   ├── priority_queue.dart        # Array-backed Binary Min-Heap
│   │   └── graph.dart                 # Weighted Directed Graph representation
│   │
│   └── theme/                         # Design Tokens matching Figma
│       ├── app_colors.dart            # Electric Lime (#C6FF00), Matte Charcoal (#18181B)
│       └── app_typography.dart        # Inter typographic hierarchy
│
├── data/
│   ├── models/
│   │   ├── waypoint_model.dart        # Geo-location node (V0, V1, V2)
│   │   ├── payment_model.dart         # PaymentDetail with Cash, COD, QRIS, Transfer
│   │   └── order_model.dart           # Order entity with box count and SKU
│   │
│   └── dummy_makassar_data.dart       # Ground truth coordinates and distance matrix
│
└── features/
    ├── controllers/
    │   └── delivery_controller.dart   # Central ChangeNotifier managing delivery lifecycle
    │
    ├── dashboard/
    │   ├── dashboard_screen.dart      # Screen 1: Courier overview & daily manifest
    │   └── widgets/                   # HeroCard, OrderCard, FloatingNavDock
    │
    ├── load_verification/
    │   ├── load_verification_screen.dart # Screen 2: LIFO trunk verification & inspection
    │   └── widgets/                   # CargoChecklistTile, AlgorithmExplainerCard
    │
    ├── route_preview/
    │   ├── route_preview_screen.dart  # Screen 3: TSP loop triangle graph & matrix view
    │   └── widgets/                   # RouteGraphCanvas, SegmentedTabSwitcher, TimelineList
    │
    └── live_navigation/
        ├── live_navigation_screen.dart# Screen 4: Turn HUD, GPS puck, & Payment console
        └── widgets/                   # TurnBannerHUD, PaymentConsoleSheet, QuickCashCalculator
```

---

## 3. Core Class Interfaces & Method Contracts

### 3.1 Struktur Data (DSA)

#### `CargoStack<T>` (`lib/core/dsa/cargo_stack.dart`)
```dart
class CargoStack<T> {
  final List<T> _storage = [];

  void push(T item) => _storage.add(item);
  T pop() {
    if (isEmpty) throw StateError('Stack is empty');
    return _storage.removeLast();
  }
  T peek() {
    if (isEmpty) throw StateError('Stack is empty');
    return _storage.last;
  }
  bool get isEmpty => _storage.isEmpty;
  int get length => _storage.length;
  List<T> toList() => List.unmodifiable(_storage);
  void clear() => _storage.clear();
}
```

#### `AdjacencyMatrix` (`lib/core/dsa/adjacency_matrix.dart`)
```dart
class AdjacencyMatrix {
  final int size;
  final List<List<double>> _matrix;

  AdjacencyMatrix(this.size)
      : _matrix = List.generate(
          size,
          (_) => List.filled(size, double.infinity),
        ) {
    for (int i = 0; i < size; i++) {
      _matrix[i][i] = 0.0;
    }
  }

  void setDistance(int from, int to, double distance) {
    _matrix[from][to] = distance;
  }

  double getDistance(int from, int to) => _matrix[from][to];

  List<List<double>> get rawMatrix => _matrix;
}
```

#### `MinHeap<T>` (`lib/core/dsa/priority_queue.dart`)
```dart
class HeapNode<T> {
  final T data;
  final double priority;
  HeapNode(this.data, this.priority);
}

class MinHeap<T> {
  final List<HeapNode<T>> _heap = [];

  int get length => _heap.length;
  bool get isEmpty => _heap.isEmpty;

  void insert(T data, double priority) {
    _heap.add(HeapNode(data, priority));
    _bubbleUp(_heap.length - 1);
  }

  T extractMin() {
    if (isEmpty) throw StateError('Heap is empty');
    final min = _heap.first.data;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return min;
  }

  void _bubbleUp(int index) { ... }
  void _bubbleDown(int index) { ... }
}
```

---

### 3.2 Desain Algoritma (DAA)

#### Abstract `TSPSolver` (`lib/core/algorithms/tsp_solver.dart`)
```dart
class TSPResult {
  final List<int> tour;            // e.g. [0, 2, 1, 0]
  final double totalDistance;      // e.g. 28.5
  final Duration executionTime;    // runtime duration
  final int operationsCount;       // iteration or state count
  final String algorithmName;      // 'Held-Karp DP' or 'Nearest Neighbor'

  const TSPResult({
    required this.tour,
    required this.totalDistance,
    required this.executionTime,
    required this.operationsCount,
    required this.algorithmName,
  });
}

abstract class TSPSolver {
  String get name;
  TSPResult solve(AdjacencyMatrix matrix, int startNode);
}
```

#### `HeldKarpTSP` (`lib/core/algorithms/held_karp_tsp.dart`)
- **Implementasi:** Memoization menggunakan array 2 dimensi `memo[1 << N][N]`.
- **Constraint:** Titik awal `startNode = 0` ($V_0$) dan titik akhir kembali ke `0`.
- **Optimalitas:** 100% Guaranteed Global Minimum.

#### `NearestNeighborTSP` (`lib/core/algorithms/nearest_neighbor_tsp.dart`)
- **Implementasi:** Array boolean `visited[N]`. Dari node aktif $u$, cari $v$ belum dikunjungi dengan $D[u][v]$ minimal. Tambahkan jarak segmen penutup $D[\text{last}][0]$.

---

## 4. State Management Architecture

Untuk menjaga kesederhanaan dan performa tinggi tanpa library eksternal yang membingungkan, kita menggunakan **`ChangeNotifier`** terpusat: `DeliveryController`.

```dart
// lib/features/controllers/delivery_controller.dart

class DeliveryController extends ChangeNotifier {
  final List<OrderModel> orders;
  final List<WaypointModel> waypoints;
  final AdjacencyMatrix distanceMatrix;
  final CargoStack<OrderModel> cargoStack = CargoStack();

  TSPResult? activeTourResult;
  int currentStopIndex = 0;
  bool isNavigating = false;

  DeliveryController({
    required this.orders,
    required this.waypoints,
    required this.distanceMatrix,
  });

  // State Mutators
  void toggleOrderVerification(String orderId) { ... notifyListeners(); }
  bool get isAllOrdersVerified => orders.every((o) => o.isVerified);

  void calculateOptimalRoute({bool useHeldKarp = true}) {
    final solver = useHeldKarp ? HeldKarpTSP() : NearestNeighborTSP();
    activeTourResult = solver.solve(distanceMatrix, 0);
    _populateCargoStackAccordingToTour();
    notifyListeners();
  }

  void completeCurrentStop(PaymentDetail payment) {
    if (!cargoStack.isEmpty) {
      cargoStack.pop();
    }
    currentStopIndex++;
    notifyListeners();
  }

  void skipCurrentStop() {
    // Dynamic re-routing: remove current node from active waypoints and re-solve TSP
    ...
    notifyListeners();
  }
}
```

---

## 5. Codex Implementation Steps (Phase-by-Phase)

Codex disarankan mengikuti urutan pengerjaan berikut agar setiap layer terverifikasi bertahap:

### Phase 1: Pure DSA Module
1. Buat `lib/core/dsa/cargo_stack.dart`
2. Buat `lib/core/dsa/adjacency_matrix.dart`
3. Buat `lib/core/dsa/priority_queue.dart`
4. Buat `lib/core/dsa/graph.dart`
5. Tulis unit test di `test/dsa_test.dart` dan jalankan `flutter test test/dsa_test.dart`.

### Phase 2: Pure DAA Solver Module
1. Buat `lib/core/algorithms/tsp_solver.dart`
2. Buat `lib/core/algorithms/held_karp_tsp.dart`
3. Buat `lib/core/algorithms/nearest_neighbor_tsp.dart`
4. Buat `lib/core/algorithms/two_opt_optimizer.dart`
5. Buat `lib/core/algorithms/dijkstra_router.dart`
6. Tulis unit test di `test/algorithms_test.dart` dan jalankan `flutter test test/algorithms_test.dart`.

### Phase 3: Domain Models & Makassar Fixture
1. Buat `lib/data/models/waypoint_model.dart`
2. Buat `lib/data/models/payment_model.dart`
3. Buat `lib/data/models/order_model.dart`
4. Buat `lib/data/dummy_makassar_data.dart`
5. Buat `bin/benchmark_tsp.dart` dan uji jalankan `dart run bin/benchmark_tsp.dart`.

### Phase 4: State Controller & UI Screens
1. Buat `lib/core/theme/app_typography.dart` (Inter typography scale & Electric Lime theme).
2. Buat `lib/features/auth/login_screen.dart` (Screen 0A: KurirGO monogram, username `ardiansyah`, PIN 4-6 digit).
3. Buat `lib/features/auth/register_screen.dart` (Screen 0B: Registrasi mitra kurir mandiri, username, PIN, tanpa upload SIM/plat).
4. Buat `lib/features/controllers/delivery_controller.dart`.
5. Buat `lib/features/dashboard/dashboard_screen.dart` (Screen 1: Manifest shift & mini route stepper).
6. Buat `lib/features/load_verification/load_verification_screen.dart` (Screen 2: Verifikasi fisik muatan bagasi LIFO).
7. Buat `lib/features/route_preview/route_preview_screen.dart` (Screen 3: Graf segitiga TSP & tombol Mulai Navigasi).
8. Buat `lib/features/live_navigation/live_navigation_screen.dart` (Screen 4: Turn-by-turn HUD, polyline jalan, panel kasir 4 metode bayar & One-tap Google Maps Intent).
9. Konfigurasi routing navigasi di `lib/main.dart`.

### Phase 5: Verification & Knowledge Sync
1. Jalankan `flutter analyze` dan pastikan 0 error.
2. Jalankan `flutter test` dan pastikan seluruh test lulus.
3. Jalankan `codegraph sync .` untuk menyinkronkan seluruh file baru ke graph proyek.



## Phase 4 — Implemented presentation contract

This section supersedes earlier UI examples where they differ. The app uses one
DeliveryController (ChangeNotifier), DeliveryScope (InheritedNotifier) and seven
named routes: /login, /register, /dashboard, /verification, /route-preview,
/navigation, /history. Each screen observes the shared controller. The root owns
and disposes its controller; an injected controller remains caller-owned.

Authentication is an in-memory demo: ardiansyah / 1234, or self-registration with
name, username, optional WhatsApp and 4–6 digit PIN. There is no server, persistent
account storage, GPS subscription, payment gateway, or real QRIS transaction.
The depot remains Pettarani; privacy requirements exclude SIM C and motor plates.

CargoStack stores one order per destination, not one entry per individual box.
Sudiang is loaded before Antang. Verification preserves both entries, route
calculation requires all orders verified, and completion pops the active order.
completeCurrentStop(payment, orderId: ...) rejects stale order IDs, insufficient
cash, pending payments and mismatched bills. Existing paid Sudiang QRIS is retained.
Calculated payment summaries use completed order bills, excluding returned change.

After both deliveries currentStopIndex=2 means return to depot. History shows the
return leg as pending; its settlement dialog confirms arrival and cash handover.
Only then is the loop marked complete. startNewRoute() loads fresh orders and
preserves the active courier account. Route guards prevent opening incomplete
preview/navigation/history. Account and delivery data reset on process restart.

Navigation uses the existing flutter_map 8.x and latlong2 dependencies.
MakassarMapView displays interactive OSM tiles, cached by flutter_map, with
stored OSRM road geometry from assets/routes/makassar_loop.json. No routing
request is made at runtime. The OSM attribution remains visible above overlays.

NavigationSimulationController owns distance, interpolated position, shortest
heading rotation, speed and the next maneuver. Flutter Ticker supplies elapsed
time, accelerated 20x for presentation. Play/Pause/Replay never modify orders,
payments or CargoStack. Backgrounding pauses playback; disposal stops tickers.
This is explicitly simulated telemetry, not device GPS. Google Maps launches
externally with the rider origin and current destination for actual navigation.

Depot V0 is now (-5.1560, 119.4350). The academic matrix still gives 28.5 km.
The stored OSRM driving route is about 40.93 km; its geographic segment lengths
drive simulation/HUD distance. These are separate datasets, never scaled to match.
After delivery two, history offers simulation of the return leg; settlement
still requires manual confirmation of return and cash handover.

url_launcher handles user-triggered telephone, WhatsApp and Google Maps.
Failures offer a copy fallback; automated tests do not send messages/calls.

UI text uses natural courier language: Riwayat Pengantaran, 2 Pesanan Selesai,
Setor Tunai ke Kasir Depot. The history metrics are Boks Terantar (5 Box / 100%),
Total Jarak (28.5 KM), and Waktu Tempuh (1 Jam 10 Mnt, fixture estimate). Settlement
is dynamic; default fixture totals are Rp150.000 cash, Rp225.000 noncash and
Rp375.000 omzet. A change in payment method changes these totals.

Styles bundle Inter (OFL) with a system sans-serif fallback, Material Icons, charcoal/lime,
54px minimum pill CTAs (radius 27), 20px cards and keyboard-safe scrolling forms.
The old -32% fuel badge is replaced with computed distance comparison: both
solvers produce 28.5 km for this fixture (0% difference). No field measurement of
fuel consumption is claimed.
