import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/payment_model.dart';

class PaymentMethodPicker extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;
  const PaymentMethodPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: PaymentMethod.values
        .map(
          (value) => ChoiceChip(
            label: Text(['COD', 'Tunai', 'QRIS', 'Transfer'][value.index]),
            selected: selected == value,
            selectedColor: AppColors.electricLime,
            labelStyle: TextStyle(
              color: selected == value
                  ? AppColors.matteCharcoal
                  : AppColors.textLight,
            ),
            onSelected: (_) => onChanged(value),
          ),
        )
        .toList(),
  );
}
