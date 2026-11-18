import 'package:flutter/material.dart';

import '../../core/number_format.dart';

import '../../data/models/order_model.dart';
import '../../data/models/payment_model.dart';
import '../shared/presentation.dart';
import 'cash_amount_fields.dart';
import 'non_cash_fields.dart';
import 'payment_method_picker.dart';

class PaymentConsole extends StatefulWidget {
  final OrderModel order;
  final bool isLastStop;
  final ValueChanged<PaymentDetail> onComplete;
  const PaymentConsole({
    required this.order,
    this.isLastStop = false,
    required this.onComplete,
    super.key,
  });
  @override
  State<PaymentConsole> createState() => _PaymentConsoleState();
}

class _PaymentConsoleState extends State<PaymentConsole> {
  final received = TextEditingController(), reference = TextEditingController();
  late PaymentMethod method = widget.order.payment.metode;
  bool confirmed = false;
  bool get prepaid =>
      method == widget.order.payment.metode &&
      widget.order.payment.status != PaymentStatus.pending;
  bool get cash => method == PaymentMethod.cod || method == PaymentMethod.cash;
  double? get amount => parseWholeNumber(received.text)?.toDouble();
  bool get ready =>
      prepaid ||
      (cash
          ? amount != null &&
                amount!.isFinite &&
                amount! >= widget.order.totalPrice
          : confirmed);
  @override
  void dispose() {
    received.dispose();
    reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'KASIR PENGANTARAN',
        style: TextStyle(
          color: Color(0xFFA1A1AA),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tagihan: ${rupiah(widget.order.totalPrice)}',
        style: const TextStyle(
          color: Color(0xFFC6FF00),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 14),
      PaymentMethodPicker(
        selected: method,
        onChanged: (value) => setState(() {
          method = value;
          confirmed = false;
          received.clear();
          reference.clear();
        }),
      ),
      const SizedBox(height: 14),
      if (prepaid)
        const Notice(
          'Pesanan sudah dibayar non-tunai (Lunas). Konfirmasi penyerahan boks kue.',
        )
      else if (cash)
        CashAmountFields(
          received: received,
          bill: widget.order.totalPrice,
          ready: ready,
          change: PaymentDetail(
            nominalTagihan: widget.order.totalPrice,
            metode: method,
            nominalDiterima: amount?.isFinite == true ? amount : null,
          ).uangKembalian,
          onChanged: () => setState(() {}),
        )
      else
        NonCashFields(
          method: method,
          reference: reference,
          confirmed: confirmed,
          onConfirmed: (value) => setState(() => confirmed = value),
        ),
      const SizedBox(height: 18),
      ActionPill(
        'Selesaikan Pengantaran Stop Ini',
        icon: Icons.check_circle_outline_rounded,
        onPressed: !ready
            ? null
            : () => widget.onComplete(
                prepaid
                    ? widget.order.payment
                    : PaymentDetail(
                        nominalTagihan: widget.order.totalPrice,
                        metode: method,
                        nominalDiterima: cash ? amount : null,
                        referensiTransaksi: reference.text.isEmpty
                            ? null
                            : reference.text,
                        status: PaymentStatus.paid,
                      ),
              ),
      ),
    ],
  );
}
