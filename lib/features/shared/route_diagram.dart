import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/dummy_makassar_data.dart';

class RouteDiagram extends StatelessWidget {
  final int activeLeg;
  const RouteDiagram({this.activeLeg = -1, super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Rute tertutup: Depot Pettarani V0, Antang V2, Sudiang V1, kembali V0. 28,5 kilometer.',
    child: AspectRatio(
      aspectRatio: 1.3,
      child: CustomPaint(painter: _RoutePainter(activeLeg)),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  final int activeLeg;
  _RoutePainter(this.activeLeg);
  @override
  void paint(Canvas canvas, Size size) {
    final points = DummyMakassarData.waypoints
        .map(
          (p) => Offset(
            34 +
                (p.longitude - 119.4350) /
                    (119.5215 - 119.4350) *
                    (size.width - 68),
            35 +
                (-5.0782 - p.latitude) /
                    (-5.0782 + 5.1685) *
                    (size.height - 78),
          ),
        )
        .toList();
    const tour = [0, 2, 1, 0], distances = ['8.2 km', '12.3 km', '8.0 km'];
    for (var i = 0; i < 3; i++) {
      final a = points[tour[i]], b = points[tour[i + 1]];
      final color = activeLeg < 0 || i == activeLeg
          ? AppColors.electricLime
          : AppColors.textLightMuted;
      final pen = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(a, b, pen);
      final mid = Offset.lerp(a, b, .5)!;
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      final arrow = Path()
        ..moveTo(
          mid.dx - 9 * math.cos(angle - .5),
          mid.dy - 9 * math.sin(angle - .5),
        )
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(
          mid.dx - 9 * math.cos(angle + .5),
          mid.dy - 9 * math.sin(angle + .5),
        );
      canvas.drawPath(arrow, pen);
      _label(canvas, distances[i], mid + const Offset(0, 12), size);
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(points[i], 8, Paint()..color = AppColors.electricLime);
      _label(
        canvas,
        ['V0 Pettarani', 'V1 Sudiang', 'V2 Antang'][i],
        points[i] + const Offset(0, -22),
        size,
      );
    }
  }

  void _label(Canvas canvas, String text, Offset center, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
          color: AppColors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = (center.dx - painter.width / 2).clamp(
      0.0,
      size.width - painter.width,
    );
    final at = Offset(left, center.dy - painter.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (at & painter.size).inflate(3),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.matteCharcoal,
    );
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.activeLeg != activeLeg;
}
