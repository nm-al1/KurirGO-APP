import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../shared/delivery_scope.dart';
import '../shared/order_card.dart';
import '../shared/presentation.dart';

class LoadVerificationScreen extends StatelessWidget {
  const LoadVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeliveryScope.of(context);
    final pendingCount = c.orders.where((o) => !o.isVerified).length;
    final isReady = c.isAllOrdersVerified;

    return Scaffold(
      backgroundColor: AppColors.matteCharcoal,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Dark Header Area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button Circle
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.darkSecondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.darkBorder, width: 1.2),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Screen Flow Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.darkSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'TAHAP 1: VERIFIKASI',
                            style: TextStyle(
                              color: AppColors.electricLime,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Brand Badge
                        const BrandBadge(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Subtitle
                  Text('Verifikasi Muatan Box', style: AppTypography.pageTitle),
                  const SizedBox(height: 3),
                  const Text(
                    'Periksa boks fisik di bagasi motor sebelum memulai rute',
                    style: TextStyle(color: AppColors.textLightMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),

                  // Cargo Summary Capsule
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.darkSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.electricLime,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total ${c.totalBoxes} Box • ${c.orders.length} Alamat',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Curved White Bottom Sheet
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    // Drag Handle Notch
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Inspection Instruction Banner (Yellow Pastel #FFFBEB)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFFF59E0B), size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pemeriksaan Fisik Bagasi Kurir',
                                  style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Pastikan segel box utuh dan temperatur kemasan terjaga.',
                                  style: TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bagasi Motor • LIFO Stack Subheader
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Text(
                            'BAGASI MOTOR • LIFO STACK',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tujuan pertama dimuat di paling atas',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Stop pertama berada di atas bagasi.
                    ...c.cargoStack.toList().reversed.map((order) {
                      return OrderCard(
                        order,
                        onToggle: () => c.toggleOrderVerification(order.id),
                      );
                    }),
                    const SizedBox(height: 8),

                    // Alert Banner: If not all verified
                    if (!isReady)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$pendingCount Pesanan Belum Terverifikasi\nCentang semua pesanan untuk mengaktifkan kalkulasi rute TSP.',
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SafeArea(
          top: false,
          child: ActionPill(
            'Urutkan Rute Loop (TSP)',
            icon: Icons.alt_route_rounded,
            onPressed: !isReady
                ? null
                : () {
                    try {
                      c.calculateOptimalRoute();
                      Navigator.pushNamed(context, '/route-preview');
                    } catch (e) {
                      showProblem(context, e);
                    }
                  },
          ),
        ),
      ),
    );
  }
}
