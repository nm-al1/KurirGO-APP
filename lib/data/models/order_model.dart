import 'payment_model.dart';

class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String itemsDescription;
  final int boxCount;
  final double totalPrice;
  final int waypointIndex;
  bool isVerified;
  PaymentDetail payment;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.itemsDescription,
    required this.boxCount,
    required this.totalPrice,
    required this.waypointIndex,
    required this.payment,
    this.isVerified = false,
  });
}
