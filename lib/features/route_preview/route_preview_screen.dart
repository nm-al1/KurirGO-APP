import 'package:flutter/material.dart';

import '../../data/models/road_route.dart';
import '../shared/delivery_scope.dart';
import '../shared/makassar_map_view.dart';
import '../shared/presentation.dart';

class RoutePreviewScreen extends StatefulWidget {
  const RoutePreviewScreen({super.key});
  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  late Future<RoadRoute> route = RoadRoute.load();
  bool showAlgorithm = false;
  @override
  Widget build(BuildContext context) {
    final c = DeliveryScope.of(context);
    final result = c.activeTourResult!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          children: [
            SizedBox(
              height: 380,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FutureBuilder<RoadRoute>(
                      future: route,
                      builder: (_, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => route = RoadRoute.load()),
                              child: const Text(
                                'Rute tidak dapat dimuat. Coba lagi',
                                style: TextStyle(color: Color(0xFF18181B)),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return MakassarMapView(route: snapshot.data!);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Material(
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white,
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Kembali ke verifikasi',
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  replaceWith(context, '/verification');
                                }
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF18181B),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${result.totalDistance.toStringAsFixed(2)} KM · Loop Tertutup',
                                style: const TextStyle(
                                  color: Color(0xFF18181B),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFF18181B),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Urutan Rute Loop'),
                          selected: !showAlgorithm,
                          onSelected: (_) =>
                              setState(() => showAlgorithm = false),
                        ),
                        ChoiceChip(
                          label: const Text('Detail Algoritma'),
                          selected: showAlgorithm,
                          onSelected: (_) =>
                              setState(() => showAlgorithm = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (showAlgorithm) ...[
                      const Text(
                        'Held-Karp Bitmask DP (Optimal)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Minimum eksak O(N² × 2ᴺ). Seluruh outlet dikunjungi sebelum kembali ke depot.',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Matriks TSP: ${result.totalDistance.toStringAsFixed(2)} KM',
                      ),
                      Text(
                        'Nearest Neighbor: ${c.comparisonResult!.totalDistance.toStringAsFixed(2)} KM',
                      ),
                    ] else
                      for (final entry in result.tour.indexed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            entry.$2 == 0
                                ? Icons.warehouse_outlined
                                : Icons.location_on,
                            color: const Color(0xFFC6FF00),
                          ),
                          title: Text(c.waypoints[entry.$2].name),
                          subtitle: Text(
                            entry.$1 == 0
                                ? 'V0 · Berangkat dari depot'
                                : entry.$1 == result.tour.length - 1
                                ? 'V0 · Pulang dan setor tunai'
                                : 'Stop #${entry.$1} · V${entry.$2}',
                          ),
                        ),
                    const SizedBox(height: 12),
                    const Text(
                      '28,5 km adalah jarak matriks akademis. Peta memakai geometri jalan OSRM tersimpan.',
                      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    ActionPill(
                      'Mulai Navigasi Rute',
                      icon: Icons.navigation_rounded,
                      onPressed: () {
                        c.startNavigation();
                        replaceWith(context, '/navigation');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
