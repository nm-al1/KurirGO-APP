import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurir_go/core/number_format.dart';

void main() {
  const formatter = IndonesianIntegerFormatter();
  TextEditingValue value(String s, [int? cursor]) => TextEditingValue(
    text: s,
    selection: TextSelection.collapsed(offset: cursor ?? s.length),
  );
  test('rupiah parser rejects fractions, negatives and malformed grouping', () {
    expect(parseWholeNumber('150000'), 150000);
    expect(parseWholeNumber('150.000'), 150000);
    for (final text in [
      '',
      '-100',
      '1,5',
      '1.5',
      'Rp 150.000',
      '1..000',
      '1000000000000',
    ]) {
      expect(parseWholeNumber(text), isNull, reason: text);
    }
    expect(decimalNumber(28.5), '28,5');
    expect(parseCoordinate('-5,1560', latitude: true), -5.156);
    expect(parseCoordinate('119.4350', latitude: false), 119.435);
    expect(parseCoordinate('NaN', latitude: true), isNull);
    expect(parseCoordinate('119.4350', latitude: true), isNull);
  });
  test(
    'typing, pasting, cursor insertion, backspace and selection deletion',
    () {
      expect(
        formatter.formatEditUpdate(value(''), value('150000')).text,
        '150.000',
      );
      expect(
        formatter.formatEditUpdate(value(''), value('150.000')).text,
        '150.000',
      );
      final inserted = formatter.formatEditUpdate(
        value('150.000', 2),
        value('1590.000', 3),
      );
      expect(inserted.text, '1.590.000');
      expect(inserted.selection.extentOffset, 4);
      final backspace = formatter.formatEditUpdate(
        value('150.000', 4),
        value('150000', 3),
      );
      expect(backspace.text, '15.000');
      expect(backspace.selection.extentOffset, 2);
      expect(formatter.formatEditUpdate(value('150.000'), value('')).text, '');
      expect(
        formatter.formatEditUpdate(value('0'), value('000150')).text,
        '150',
      );
      expect(
        formatter.formatEditUpdate(value('150'), value('-150')).text,
        '150',
      );
      expect(
        formatter.formatEditUpdate(value('150'), value('150,5')).text,
        '150',
      );
    },
  );
}
