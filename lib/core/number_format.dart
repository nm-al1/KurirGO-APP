import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const maxRupiah = 999999999999;
String groupedNumber(num value) => NumberFormat('#,##0', 'id_ID').format(value);
String decimalNumber(num value) =>
    NumberFormat('#,##0.#', 'id_ID').format(value);

int? parseWholeNumber(String text) {
  if (!RegExp(r'^(?:\d+|\d{1,3}(?:\.\d{3})+)$').hasMatch(text)) return null;
  final value = int.tryParse(text.replaceAll('.', ''));
  return value != null && value <= maxRupiah ? value : null;
}

double? parseCoordinate(String text, {required bool latitude}) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite && value.abs() <= (latitude ? 90 : 180)
      ? value
      : null;
}

class IndonesianIntegerFormatter extends TextInputFormatter {
  const IndonesianIntegerFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    if (newValue.text.isEmpty) return newValue;
    if (!RegExp(r'^[0-9.]+$').hasMatch(newValue.text)) return oldValue;
    final insertedLength =
        newValue.text.length -
        oldValue.text.length +
        (oldValue.selection.end - oldValue.selection.start);
    if (newValue.text.contains('.') &&
        insertedLength > 1 &&
        parseWholeNumber(newValue.text) == null) {
      return oldValue;
    }
    if (insertedLength == 1 &&
        '.'.allMatches(newValue.text).length >
            '.'.allMatches(oldValue.text).length &&
        parseWholeNumber(newValue.text) == null) {
      return oldValue;
    }
    var raw = newValue.text.replaceAll('.', '');
    var before = newValue.text
        .substring(
          0,
          newValue.selection.extentOffset.clamp(0, newValue.text.length),
        )
        .replaceAll('.', '')
        .length;
    // Backspacing a separator removes the preceding digit, not a regenerated dot.
    if (oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed &&
        oldValue.text.length == newValue.text.length + 1 &&
        oldValue.selection.extentOffset ==
            newValue.selection.extentOffset + 1 &&
        oldValue.text[newValue.selection.extentOffset] == '.' &&
        before > 0) {
      raw = raw.substring(0, before - 1) + raw.substring(before);
      before--;
    }
    if (raw.isEmpty) return const TextEditingValue();
    final value = int.tryParse(raw);
    if (value == null || value > maxRupiah) return oldValue;
    final formatted = groupedNumber(value);
    final leadingRemoved = raw.length - value.toString().length;
    final wanted = (before - leadingRemoved).clamp(0, formatted.length);
    var cursor = 0, digits = 0;
    while (cursor < formatted.length && digits < wanted) {
      if (formatted[cursor] != '.') digits++;
      cursor++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
