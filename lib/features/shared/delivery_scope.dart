import 'package:flutter/widgets.dart';

import '../controllers/delivery_controller.dart';

class DeliveryScope extends InheritedNotifier<DeliveryController> {
  const DeliveryScope({
    required DeliveryController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);
  static DeliveryController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeliveryScope>()!.notifier!;
}
