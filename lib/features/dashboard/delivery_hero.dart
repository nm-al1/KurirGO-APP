import 'package:flutter/material.dart';

import '../controllers/delivery_controller.dart';
import 'mini_route_stepper.dart';

class DeliveryHero extends StatelessWidget {
  final DeliveryController controller;
  const DeliveryHero({required this.controller, super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF18181B),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(color: Color(0x22000000), offset: Offset(0, 5)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'RUTE HARI INI',
              style: TextStyle(
                color: Color(0xFFC6FF00),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${controller.completedOrders.length}/${controller.orders.length} Selesai',
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${controller.totalBoxes} Box Kue',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${controller.orders.length} Alamat \u00B7 Total 28.5 KM \u00B7 Estimasi 1 Jam 10 Mnt \u00B7 Loop Tertutup',
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
        ),
        const SizedBox(height: 16),
        MiniRouteStepper(controller: controller),
      ],
    ),
  );
}
