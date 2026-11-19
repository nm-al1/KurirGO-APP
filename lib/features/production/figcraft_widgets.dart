import 'package:flutter/material.dart';

import '../../core/number_format.dart';
import '../../data/courier_store.dart';
import '../controllers/courier_runtime.dart';
import '../shared/presentation.dart' show BrandBadge;
import 'app.dart';

ThemeData figcraftDarkTheme(BuildContext context) => Theme.of(context).copyWith(
  hintColor: const Color(0xFFA1A1AA),
  colorScheme: const ColorScheme.dark(
    primary: lime,
    onPrimary: ink,
    surface: ink,
    onSurface: Colors.white,
  ),
  textTheme: Theme.of(context).textTheme
      .apply(bodyColor: Colors.white, displayColor: Colors.white),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF27272A),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
    hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
  ),
);

class CourierIdentity extends StatelessWidget {
  final CourierRuntime runtime;
  final VoidCallback? onSync;
  const CourierIdentity(this.runtime, {this.onSync, super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CourierAvatar(runtime),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${runtime.fullName}!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Hub Pettarani · Makassar',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              runtime.activeTrip == null ? 'Siap Antar' : 'Sedang mengantar',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF047857),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      const BrandBadge(),
    ],
  );
}

class FigcraftTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const FigcraftTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 360 ? 4 : 20,
        8,
        MediaQuery.sizeOf(context).width < 360 ? 4 : 20,
        12,
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            for (final entry in [
              (Icons.home_outlined, 'Home'),
              (Icons.history, 'Riwayat'),
              (Icons.bar_chart, 'Performa'),
              (Icons.person_outline, 'Profil'),
            ].indexed)
              Expanded(
                flex: MediaQuery.textScalerOf(context).scale(10) > 13
                    ? [8, 11, 13, 8][entry.$1]
                    : 1,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 10,
                    ),
                    animationDuration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    minimumSize: const Size(48, 48),
                    foregroundColor: selected == entry.$1 ? ink : Colors.white,
                    backgroundColor: selected == entry.$1
                        ? lime
                        : Colors.transparent,
                  ),
                  onPressed: () => onChanged(entry.$1),
                  child: Flex(
                    direction:
                        MediaQuery.sizeOf(context).width >= 390 &&
                            MediaQuery.textScalerOf(context).scale(10) <= 11
                        ? Axis.horizontal
                        : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(entry.$2.$1, size: 19),
                      const SizedBox(height: 3, width: 4),
                      Text(
                        entry.$2.$2,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class InkPanel extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const InkPanel(
    this.children, {
    this.padding = const EdgeInsets.all(18),
    super.key,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: ink,
    borderRadius: BorderRadius.circular(22),
    child: Padding(
      padding: padding,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class RouteStrip extends StatelessWidget {
  final CourierRuntime runtime;
  const RouteStrip(this.runtime, {super.key});
  @override
  Widget build(BuildContext context) {
    final trip = runtime.activeTrip;
    final stops = trip == null ? <dynamic>[] : trip['stops'] as List;
    final labels = [
      'DEPOT',
      for (var i = 0; i < stops.length; i++) '#${i + 1}',
      'PULANG',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in labels.indexed) ...[
              if (entry.$1 > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.east, size: 16, color: lime),
                ),
              Column(
                children: [
                  Icon(
                    entry.$1 == 0 || entry.$1 == labels.length - 1
                        ? Icons.warehouse_outlined
                        : Icons.location_on_outlined,
                    color: lime,
                    size: 20,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.$2,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DeliverySummary extends StatelessWidget {
  final CourierRuntime runtime;
  const DeliverySummary(this.runtime, {super.key});
  @override
  Widget build(BuildContext context) {
    final trip = runtime.activeTrip;
    final orders = trip == null
        ? runtime.waiting
        : runtime.orders.where((o) => o['tripId'] == trip['id']).toList();
    final boxes = orders.fold<int>(0, (sum, o) => sum + (o['boxes'] as int));
    return InkPanel([
      Row(
        children: [
          const Expanded(
            child: Text(
              'RUTE HARI INI',
              style: TextStyle(
                color: lime,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          Text(
            '${orders.where((o) => o['status'] == 'completed').length}/${orders.length} Selesai',
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        '${groupedNumber(boxes)} Box Kue',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 5),
      Text(
        trip == null
            ? '${orders.length} Pesanan · Siap disusun · Loop tertutup'
            : '${(trip['stops'] as List).length} Alamat · ${decimalNumber((trip['distance'] as num) / 1000)} km · ${groupedNumber(((trip['duration'] as num) / 60).ceil())} menit · Loop tertutup',
        style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10),
      ),
      const SizedBox(height: 14),
      RouteStrip(runtime),
    ]);
  }
}

class SmallMetric extends StatelessWidget {
  final String label, value;
  const SmallMetric(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class WeekChart extends StatelessWidget {
  final List<Json> history;
  const WeekChart(this.history, {super.key});
  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final counts = List.generate(
      7,
      (i) => history
          .where(
            (o) => DateUtils.isSameDay(
              DateTime.parse(o['completedAt']).toLocal(),
              today.subtract(Duration(days: 6 - i)),
            ),
          )
          .fold<int>(0, (sum, o) => sum + (o['boxes'] as int)),
    );
    final max = counts.fold<int>(1, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOX TERANTAR MINGGU INI',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 136,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Semantics(
                      label: '${counts[i]} box terantar',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${counts[i]}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 18,
                            height: counts[i] == 0 ? 3 : 75 * counts[i] / max,
                            decoration: BoxDecoration(
                              color: i == 6 ? lime : ink,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              'Sen',
                              'Sel',
                              'Rab',
                              'Kam',
                              'Jum',
                              'Sab',
                              'Min',
                            ][today.subtract(Duration(days: 6 - i)).weekday -
                                1],
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Belum ada pengantaran selesai.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
        ],
      ),
    );
  }
}

class CourierAvatar extends StatelessWidget {
  final CourierRuntime runtime;
  final double radius;
  const CourierAvatar(this.runtime, {this.radius = 21, super.key});
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: ink,
    foregroundColor: lime,
    backgroundImage: runtime.avatar == null
        ? null
        : MemoryImage(runtime.avatar!),
    child: runtime.avatar == null
        ? Text(
            runtime.fullName.isEmpty
                ? 'K'
                : runtime.fullName.characters.first.toUpperCase(),
          )
        : null,
  );
}
