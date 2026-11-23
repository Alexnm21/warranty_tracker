import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/extensions/datetime_extensions.dart';

void main() {
  group('dateString', () {
    test('formats a date as day, 3-letter month and year', () {
      expect(DateTime(2028, 3, 12).dateString, '12 Mar 2028');
    });

    test('formats single digit days without padding', () {
      expect(DateTime(2026, 1, 5).dateString, '5 Jan 2026');
    });

    test('uses a short month name for every month of the year', () {
      const expected = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      for (var month = 1; month <= 12; month++) {
        expect(
          DateTime(2027, month, 15).dateString,
          '15 ${expected[month - 1]} 2027',
        );
      }
    });
  });
}
