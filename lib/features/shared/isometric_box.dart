import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Authentic 3D Isometric Browcyl Cake Box matching Figma Comp/Isometric3DBox
/// Top Facet: #E3BA87 (light brown)
/// Left Facet: #C79966 (medium shadow brown)
/// Right Facet: #AB7D4F (deep shadow brown)
/// Tape: Electric Lime #C6FF00 or light tape
class IsometricBox extends StatelessWidget {
  final double size;
  final bool hasTape;
  final Color? tapeColor;

  const IsometricBox({
    super.key,
    this.size = 48,
    this.hasTape = true,
    this.tapeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IsometricBoxPainter(
          hasTape: hasTape,
          tapeColor: tapeColor ?? AppColors.electricLime,
        ),
      ),
    );
  }
}

class _IsometricBoxPainter extends CustomPainter {
  final bool hasTape;
  final Color tapeColor;

  _IsometricBoxPainter({required this.hasTape, required this.tapeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale coordinates normalized to 56x56
    final sx = w / 56.0;
    final sy = h / 56.0;

    Offset pt(double x, double y) => Offset(x * sx, y * sy);

    // 1. Top Facet (Light brown #E3BA87)
    final topPath = Path()
      ..moveTo(pt(28, 6).dx, pt(28, 6).dy)
      ..lineTo(pt(50, 18).dx, pt(50, 18).dy)
      ..lineTo(pt(28, 30).dx, pt(28, 30).dy)
      ..lineTo(pt(6, 18).dx, pt(6, 18).dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = const Color(0xFFE3BA87));

    // 2. Left Facet (Medium brown #C79966)
    final leftPath = Path()
      ..moveTo(pt(6, 18).dx, pt(6, 18).dy)
      ..lineTo(pt(28, 30).dx, pt(28, 30).dy)
      ..lineTo(pt(28, 52).dx, pt(28, 52).dy)
      ..lineTo(pt(6, 40).dx, pt(6, 40).dy)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = const Color(0xFFC79966));

    // 3. Right Facet (Deep brown #AB7D4F)
    final rightPath = Path()
      ..moveTo(pt(28, 30).dx, pt(28, 30).dy)
      ..lineTo(pt(50, 18).dx, pt(50, 18).dy)
      ..lineTo(pt(50, 40).dx, pt(50, 40).dy)
      ..lineTo(pt(28, 52).dx, pt(28, 52).dy)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = const Color(0xFFAB7D4F));

    // 4. Browcyl Green Packaging Tape
    if (hasTape) {
      final tapeTop = Path()
        ..moveTo(pt(25, 7.5).dx, pt(25, 7.5).dy)
        ..lineTo(pt(31, 10.5).dx, pt(31, 10.5).dy)
        ..lineTo(pt(31, 30.5).dx, pt(31, 30.5).dy)
        ..lineTo(pt(25, 28).dx, pt(25, 28).dy)
        ..close();
      canvas.drawPath(tapeTop, Paint()..color = tapeColor.withValues(alpha: 0.95));

      final tapeLeft = Path()
        ..moveTo(pt(25, 28).dx, pt(25, 28).dy)
        ..lineTo(pt(31, 30.5).dx, pt(31, 30.5).dy)
        ..lineTo(pt(31, 52).dx, pt(31, 52).dy)
        ..lineTo(pt(25, 49.5).dx, pt(25, 49.5).dy)
        ..close();
      canvas.drawPath(tapeLeft, Paint()..color = tapeColor);
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricBoxPainter oldDelegate) =>
      oldDelegate.hasTape != hasTape || oldDelegate.tapeColor != tapeColor;
}

