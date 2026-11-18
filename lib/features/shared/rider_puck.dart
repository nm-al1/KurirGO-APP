import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RiderPuck extends StatefulWidget {
  final double heading;
  final bool moving;
  const RiderPuck({required this.heading, required this.moving, super.key});
  @override
  State<RiderPuck> createState() => _RiderPuckState();
}

class _RiderPuckState extends State<RiderPuck>
    with SingleTickerProviderStateMixin {
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  void syncPulse() {
    if (widget.moving && !MediaQuery.disableAnimationsOf(context)) {
      if (!pulse.isAnimating) pulse.repeat(reverse: true);
    } else {
      pulse.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncPulse();
  }

  @override
  void didUpdateWidget(covariant RiderPuck oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncPulse();
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: pulse,
    builder: (_, _) => Semantics(
      label: 'Posisi kurir simulasi',
      child: Center(
        child: Container(
          width: 46 + pulse.value * 14,
          height: 46 + pulse.value * 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.electricLime.withValues(alpha: .22),
          ),
          child: Center(
            child: Transform.rotate(
              angle: widget.heading * math.pi / 180,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.matteCharcoal,
                  border: Border.all(color: AppColors.electricLime, width: 3),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -5,
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: AppColors.electricLime,
                        size: 22,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
