import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/utils/price_format.dart';

void main() {
  group('parsePrice', () {
    test('parses a decimal value into minor units', () {
      expect(parsePrice('899.99'), 89999);
    });

    test('accepts a comma as the decimal separator', () {
      expect(parsePrice('899,99'), 89999);
    });

    test('treats a whole number as major units', () {
      expect(parsePrice('12'), 1200);
    });

    test('accepts zero', () {
      expect(parsePrice('0'), 0);
      expect(parsePrice('0.00'), 0);
    });

    test('returns null for a blank value', () {
      expect(parsePrice('   '), isNull);
    });

    test('returns null for a non-numeric value', () {
      expect(parsePrice('abc'), isNull);
    });

    test('returns null for a negative value', () {
      expect(parsePrice('-5'), isNull);
    });
  });
}
