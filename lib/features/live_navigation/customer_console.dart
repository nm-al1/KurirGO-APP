import 'package:flutter/material.dart';

import '../../data/models/order_model.dart';
import '../../data/models/payment_model.dart';
import '../shared/external_actions.dart';
import 'payment_console.dart';

class CustomerConsole extends StatelessWidget {
  final OrderModel order;
  final bool isLastStop;
  final ValueChanged<PaymentDetail> onComplete;
  const CustomerConsole({
    required this.order,
    required this.isLastStop,
    required this.onComplete,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF18181B),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.customerName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${order.id} · ${order.itemsDescription}',
            style: const TextStyle(color: Color(0xFFA1A1AA)),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => launchCourierLink(
                  context,
                  callUri(order.customerPhone),
                  order.customerPhone,
                ),
                icon: const Icon(Icons.phone),
                label: const Text('Telepon'),
              ),
              TextButton.icon(
                onPressed: () => launchCourierLink(
                  context,
                  chatUri(order.customerPhone),
                  order.customerPhone,
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('WhatsApp'),
              ),
            ],
          ),
          const Divider(),
          PaymentConsole(
            key: ValueKey(order.id),
            order: order,
            isLastStop: isLastStop,
            onComplete: onComplete,
          ),
        ],
      ),
    ),
  );
}
