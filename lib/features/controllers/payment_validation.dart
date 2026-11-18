import '../../data/models/order_model.dart';
import '../../data/models/payment_model.dart';

void validateDeliveryPayment(OrderModel order, PaymentDetail payment) {
  final cash =
      payment.metode == PaymentMethod.cod ||
      payment.metode == PaymentMethod.cash;
  final prepaid =
      identical(payment, order.payment) &&
      payment.status != PaymentStatus.pending;
  if (payment.nominalTagihan != order.totalPrice ||
      payment.status == PaymentStatus.pending ||
      (cash &&
          !prepaid &&
          (payment.nominalDiterima ?? -1) < order.totalPrice)) {
    throw ArgumentError('Pembayaran belum lengkap atau uang diterima kurang.');
  }
}
