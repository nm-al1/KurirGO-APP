import 'package:flutter/material.dart';

import '../../core/number_format.dart';

import '../../core/theme/app_colors.dart';
import '../shared/presentation.dart';

class CashAmountFields extends StatelessWidget {
  final TextEditingController received;
  final double bill, change;
  final bool ready;
  final VoidCallback onChanged;
  const CashAmountFields({
    required this.received,
    required this.bill,
    required this.change,
    required this.ready,
    required this.onChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: received,
        keyboardType: TextInputType.number,
        inputFormatters: [const IndonesianIntegerFormatter()],
        onChanged: (_) => onChanged(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(
          labelText: 'Uang Diterima (Rp)',
          hintText: 'Contoh: 150.000',
          prefixText: 'Rp  ',
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final entry in <(String, double)>[
            ('Uang Pas', bill),
            ('Rp 50.000', 50000),
            ('Rp 100.000', 100000),
            ('Rp 150.000', 150000),
            ('Rp 200.000', 200000),
          ])
            ActionChip(
              label: Text(entry.$1),
              backgroundColor: AppColors.darkSecondary,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              onPressed: () {
                received.text = groupedNumber(entry.$2);
                onChanged();
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Kembalian: ${rupiah(change)}',
        style: const TextStyle(
          color: AppColors.electricLime,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (received.text.isNotEmpty && !ready)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Uang diterima belum mencukupi nominal tagihan.',
            style: TextStyle(color: Color(0xFFFCA5A5)),
          ),
        ),
    ],
  );
}
