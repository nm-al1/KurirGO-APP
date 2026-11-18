import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapControls extends StatelessWidget {
  final MapController controller;
  final bool following;
  final VoidCallback recenter;
  final VoidCallback? overview;
  const MapControls({
    required this.controller,
    required this.following,
    required this.recenter,
    this.overview,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF18181B),
    borderRadius: BorderRadius.circular(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overview != null)
          IconButton(
            tooltip: 'Lihat seluruh rute',
            onPressed: overview,
            icon: const Icon(Icons.route),
            color: Colors.white,
            constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
          ),
        IconButton(
          tooltip: following ? 'Posisi kurir terkunci' : 'Kunci posisi kurir',
          onPressed: recenter,
          icon: Icon(following ? Icons.gps_fixed : Icons.gps_not_fixed),
          color: const Color(0xFFC6FF00),
          constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
        ),
        for (final step in [1.0, -1.0])
          IconButton(
            tooltip: step > 0 ? 'Perbesar peta' : 'Perkecil peta',
            constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
            onPressed: () => controller.move(
              controller.camera.center,
              (controller.camera.zoom + step).clamp(5, 19),
            ),
            icon: Icon(step > 0 ? Icons.add : Icons.remove),
            color: Colors.white,
          ),
      ],
    ),
  );
}
