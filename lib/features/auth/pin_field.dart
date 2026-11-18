import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  const PinField({
    required this.controller,
    this.label = 'PIN',
    this.validator,
    super.key,
  });
  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  bool hidden = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: hidden,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        tooltip: hidden ? 'Tampilkan PIN' : 'Sembunyikan PIN',
        onPressed: () => setState(() => hidden = !hidden),
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator:
        widget.validator ??
        (value) => RegExp(r'^\d{4,6}$').hasMatch(value ?? '')
            ? null
            : 'PIN harus 4–6 digit.',
  );
}
