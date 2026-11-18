import 'package:flutter/material.dart';

import '../controllers/delivery_controller.dart';
import '../shared/presentation.dart';

class CourierHeader extends StatelessWidget {
  final DeliveryController controller;
  const CourierHeader({required this.controller, super.key});
  @override
  Widget build(BuildContext context) {
    final account = controller.account;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, ${account.fullName}!',
          style: const TextStyle(
            color: Color(0xFF18181B),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hub Pettarani \u00B7 Makassar',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          controller.isSettled
              ? 'Pengantaran selesai'
              : controller.isNavigating
              ? 'Sedang mengantar'
              : 'Siap Antar',
          style: const TextStyle(
            color: Color(0xFF047857),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF18181B),
      foregroundColor: const Color(0xFFC6FF00),
      child: Text(
        account.fullName.isEmpty ? 'K' : account.fullName[0].toUpperCase(),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 330 ||
            MediaQuery.textScalerOf(context).scale(17) > 22) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [avatar, const BrandBadge()],
              ),
              const SizedBox(height: 12),
              details,
            ],
          );
        }
        return Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: details),
            const SizedBox(width: 8),
            const BrandBadge(),
          ],
        );
      },
    );
  }
}
