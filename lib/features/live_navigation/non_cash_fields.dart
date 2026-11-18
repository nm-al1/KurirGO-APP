import 'package:flutter/material.dart';

import '../../data/models/payment_model.dart';
import '../shared/presentation.dart';

class NonCashFields extends StatelessWidget {
  final PaymentMethod method;
  final TextEditingController reference;
  final bool confirmed;
  final ValueChanged<bool> onConfirmed;
  const NonCashFields({
    required this.method,
    required this.reference,
    required this.confirmed,
    required this.onConfirmed,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Notice(
        method == PaymentMethod.qris
            ? 'Simulasi QRIS. Kode contoh tidak dapat digunakan untuk membayar.'
            : 'Simulasi Transfer Bank. Pastikan bukti transfer terverifikasi.',
      ),
      if (method == PaymentMethod.qris)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 88,
                color: Color(0xFF18181B),
                semanticLabel: 'Contoh QRIS simulasi',
              ),
            ),
          ),
        ),
      TextField(
        controller: reference,
        decoration: const InputDecoration(
          labelText: 'Referensi Transaksi (Opsional)',
          hintText: 'Contoh: TRX-99881',
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Pembayaran sudah dikonfirmasi masuk rekening'),
        value: confirmed,
        onChanged: (v) => onConfirmed(v ?? false),
      ),
    ],
  );
}
