import 'package:flutter/material.dart';

import '../controllers/navigation_simulation_controller.dart';

class NavigationHud extends StatelessWidget {
  final NavigationSimulationController simulation;
  final String destination;
  final VoidCallback onToggle, onReplay, onMaps;
  const NavigationHud({
    required this.simulation,
    required this.destination,
    required this.onToggle,
    required this.onReplay,
    required this.onMaps,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final s = simulation;
    final modifier = s.maneuver.modifier;
    final icon = s.arrived
        ? Icons.flag_rounded
        : modifier.contains('right')
        ? Icons.turn_right_rounded
        : modifier.contains('left')
        ? Icons.turn_left_rounded
        : modifier == 'uturn'
        ? Icons.u_turn_right
        : Icons.straight;
    return Material(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(22),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destination,
              style: const TextStyle(
                color: Color(0xFFC6FF00),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 36, color: const Color(0xFFC6FF00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.arrived
                            ? 'Tiba di Tujuan'
                            : '${s.distanceToTurn.round()} M',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(s.instruction, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Simulasi 20× · ${s.speed.round()} km/h · Akurasi simulasi ±3 m',
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: s.arrived ? null : onToggle,
                  icon: Icon(s.running ? Icons.pause : Icons.play_arrow),
                  label: Text(s.running ? 'Jeda' : 'Putar'),
                ),
                IconButton(
                  tooltip: 'Ulangi simulasi',
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay),
                ),
                TextButton.icon(
                  onPressed: onMaps,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Google Maps'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
