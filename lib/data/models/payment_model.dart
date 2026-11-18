import 'dart:math';

enum PaymentMethod { cod, cash, qris, transfer }

enum PaymentStatus { pending, paid, verified }

class PaymentDetail {
  final double nominalTagihan;
  final double? nominalDiterima;
  final PaymentMethod metode;
  PaymentStatus status;
  final String? referensiTransaksi;

  PaymentDetail({
    required this.nominalTagihan,
    required this.metode,
    this.nominalDiterima,
    this.status = PaymentStatus.pending,
    this.referensiTransaksi,
  }) {
    for (final value in [nominalTagihan, nominalDiterima]) {
      if (value != null && (!value.isFinite || value < 0)) {
        throw ArgumentError.value(
          value,
          'nominal',
          'Must be finite and nonnegative',
        );
      }
    }
  }

  double get uangKembalian =>
      metode == PaymentMethod.cash || metode == PaymentMethod.cod
      ? max(0.0, (nominalDiterima ?? 0) - nominalTagihan)
      : 0.0;
}
