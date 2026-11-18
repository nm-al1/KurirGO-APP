import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class Notice extends StatelessWidget {
  final String text;
  final IconData icon;
  const Notice(this.text, {this.icon = Icons.info_outline_rounded, super.key});
  @override
  Widget build(BuildContext context) {
    final warning = icon == Icons.warning_amber_rounded;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: warning ? AppColors.textDark : AppColors.electricLime,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyStreet.copyWith(
              color: warning ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ),
      ],
    );
    return warning
        ? Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusAmberBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: content,
          )
        : content;
  }
}
