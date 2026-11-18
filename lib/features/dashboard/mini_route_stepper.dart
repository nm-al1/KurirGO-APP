import 'package:flutter/material.dart';

import '../controllers/delivery_controller.dart';

class MiniRouteStepper extends StatelessWidget {
  final DeliveryController controller;
  const MiniRouteStepper({required this.controller, super.key});
  @override
  Widget build(BuildContext context) {
    const labels = ['DEPOT', '#1 ANTANG', '#2 SUDIANG', 'PULANG (DEPOT)'];
    final current = controller.isSettled
        ? 3
        : controller.isNavigating
        ? controller.currentStopIndex + 1
        : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth < 290 ||
                  MediaQuery.textScalerOf(context).scale(12) > 15
              ? 2
              : 4;
          return Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              for (var i = 0; i < labels.length; i++)
                SizedBox(
                  width: (constraints.maxWidth - 8 * (columns - 1)) / columns,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        i < current
                            ? Icons.check_circle
                            : i == 0 || i == 3
                            ? Icons.warehouse_outlined
                            : Icons.location_on,
                        color: i <= current
                            ? const Color(0xFFC6FF00)
                            : const Color(0xFFA1A1AA),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: i <= current
                              ? Colors.white
                              : const Color(0xFFA1A1AA),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
