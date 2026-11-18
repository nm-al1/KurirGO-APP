import 'package:flutter/material.dart';

import '../shared/delivery_scope.dart';
import '../shared/order_card.dart';
import '../shared/presentation.dart';
import 'courier_header.dart';
import 'delivery_hero.dart';
import '../profile/courier_pages.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = DeliveryScope.of(context);
    final label = c.isSettled
        ? 'Mulai Rute Baru'
        : c.currentStopIndex == 2
        ? 'Kembali & Setor ke Depot'
        : c.isNavigating
        ? 'Lanjutkan Pengantaran (Stop #${c.currentStopIndex + 1})'
        : 'Mulai Muat Barang (LIFO Stack)';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CourierHeader(controller: c),
            const SizedBox(height: 22),
            DeliveryHero(controller: c),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daftar Pesanan Siap Kirim',
                    style: TextStyle(
                      color: Color(0xFF18181B),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${c.orders.length} Pesanan',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final order in c.orders) OrderCard(order, isDashboard: true),
            const SizedBox(height: 24),
            const CourierTabs(selected: 0),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ActionPill(
          label,
          icon: Icons.inventory_2_outlined,
          onPressed: () {
            if (c.isSettled) c.startNewRoute();
            Navigator.pushNamed(
              context,
              c.isNavigating
                  ? c.currentStopIndex == 2
                        ? '/history'
                        : '/navigation'
                  : '/verification',
            );
          },
        ),
      ),
    );
  }
}
