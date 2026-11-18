import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../shared/delivery_scope.dart';
import '../shared/presentation.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeliveryScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => replaceWith(context, '/dashboard'),
        ),
        title: const Text(
          'Pengantaran Selesai',
          style: TextStyle(fontSize: 13),
        ),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: BrandBadge()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Riwayat Pengantaran',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${c.completedOrders.length} Pesanan Selesai • Cabang Pettarani',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SETORAN KASIR CABANG',
                  style: TextStyle(
                    color: AppColors.electricLime,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    _total(
                      'Tunai / COD (Wajib Setor)',
                      rupiah(c.cashToDeposit),
                      AppColors.electricLime,
                    ),
                    _total(
                      'Non-Tunai (QRIS/Transfer)',
                      rupiah(c.nonCashTotal),
                      Colors.white,
                    ),
                  ],
                ),
                const Divider(color: AppColors.darkBorder),
                Text('Total Omzet Pengantaran: ${rupiah(c.revenue)}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('Box Terantar', '${c.boxesDelivered} Box / 100%'),
              _metric('Total Jarak', '28.5 KM'),
              _metric('Estimasi Fixture', '1 Jam 10 Mnt'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Rincian Pengantaran Hari Ini',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final (index, order) in c.completedOrders.indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.matteCharcoal,
                  foregroundColor: AppColors.electricLime,
                  child: Text('#${index + 1}'),
                ),
                title: Text(
                  order.customerName,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${order.id} • ${order.boxCount} Box\n${rupiah(order.payment.nominalTagihan)} • Lunas',
                  style: const TextStyle(color: AppColors.statusGreen),
                ),
              ),
            ),
          if (!c.isSettled)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.textDark),
              onPressed: () => Navigator.pushNamed(context, '/navigation'),
              icon: const Icon(Icons.navigation),
              label: const Text('Simulasikan Pulang ke Depot'),
            ),
          const Text(
            'Pencatatan pembayaran demo. Konfirmasi setoran dilakukan manual di depot.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ActionPill(
          c.isSettled ? 'Kembali ke Dashboard' : 'Setor Tunai ke Kasir Depot',
          icon: Icons.account_balance_wallet_outlined,
          onPressed: () async {
            if (c.isSettled) {
              replaceWith(context, '/dashboard');
              return;
            }
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Konfirmasi Setoran Depot'),
                content: Text(
                  'Sudah kembali ke Cabang Pettarani dan siap menyerahkan ${rupiah(c.cashToDeposit)} ke kasir?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Belum'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sudah Kembali & Setor'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              c.settleAtDepot();
              replaceWith(context, '/dashboard');
            }
          },
        ),
      ),
    );
  }

  Widget _total(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textLightMuted, fontSize: 11),
      ),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _metric(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
