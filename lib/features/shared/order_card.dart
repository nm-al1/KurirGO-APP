import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/order_model.dart';
import 'isometric_box.dart';
import 'presentation.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onToggle;
  final bool isDashboard;
  const OrderCard(
    this.order, {
    this.onToggle,
    this.isDashboard = false,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final dark = !isDashboard && order.isVerified;
    final foreground = dark ? Colors.white : AppColors.textDark;
    final secondary = dark ? AppColors.textLightMuted : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: dark ? AppColors.matteCharcoal : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.borderLight,
          ),
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IsometricBox(
                  size: 44,
                  tapeColor: isDashboard || order.isVerified
                      ? AppColors.electricLime
                      : const Color(0xFFCBD5E1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onToggle != null) ...[
                        Text(
                          order.waypointIndex == 2
                              ? 'BAGASI ATAS #1'
                              : 'BAGASI BAWAH #2',
                          style: TextStyle(
                            color: dark
                                ? AppColors.electricLime
                                : AppColors.statusGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            order.id,
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${order.boxCount} Box',
                            style: TextStyle(color: secondary, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        order.customerName,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.itemsDescription,
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rupiah(order.totalPrice),
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (onToggle != null)
                        Text(
                          order.isVerified
                              ? 'Terverifikasi'
                              : 'Belum Terverifikasi',
                          style: TextStyle(color: secondary, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (onToggle != null)
                  Checkbox(
                    value: order.isVerified,
                    semanticLabel: 'Verifikasi ${order.id}',
                    onChanged: (_) => onToggle!(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
