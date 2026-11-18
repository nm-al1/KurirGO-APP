import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MetricCapsule extends StatelessWidget {
  final String label;
  final String value;
  const MetricCapsule(this.label, this.value, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.darkBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyStreet),
        const SizedBox(height: 5),
        Text(
          value,
          style: AppTypography.sectionTitle.copyWith(
            color: AppColors.electricLime,
          ),
        ),
      ],
    ),
  );
}
