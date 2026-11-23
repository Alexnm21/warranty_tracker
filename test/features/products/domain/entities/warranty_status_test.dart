import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/warranty_status.dart';

void main() {
  group('WarrantyStatus.fromDates', () {
    test('is future when today is before the start date', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2026, 1, 10),
        DateTime(2026, 2, 1),
        DateTime(2026, 1, 5),
      );

      expect(status, WarrantyStatus.future);
    });

    test('is active when today is between start and end', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
        DateTime(2026, 6, 15),
      );

      expect(status, WarrantyStatus.active);
    });

    test('is expired when today is after the end date', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2025, 1, 1),
        DateTime(2025, 12, 31),
        DateTime(2026, 3, 1),
      );

      expect(status, WarrantyStatus.expired);
    });

    test('is active on the start date', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2026, 6, 15),
        DateTime(2026, 12, 31),
        DateTime(2026, 6, 15),
      );

      expect(status, WarrantyStatus.active);
    });

    test('treats the end date as inclusive', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2025, 1, 1),
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 15),
      );

      expect(status, WarrantyStatus.active);
    });

    test('expires on the day after the end date', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2025, 1, 1),
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 16),
      );

      expect(status, WarrantyStatus.expired);
    });

    test('ignores the time of day on the end date', () {
      final status = WarrantyStatus.fromDates(
        DateTime(2025, 1, 1),
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 15, 23, 59),
      );

      expect(status, WarrantyStatus.active);
    });

    test('supports a same-day start and end', () {
      expect(
        WarrantyStatus.fromDates(
          DateTime(2026, 6, 15),
          DateTime(2026, 6, 15),
          DateTime(2026, 6, 15),
        ),
        WarrantyStatus.active,
      );
      expect(
        WarrantyStatus.fromDates(
          DateTime(2026, 6, 15),
          DateTime(2026, 6, 15),
          DateTime(2026, 6, 16),
        ),
        WarrantyStatus.expired,
      );
    });

    test('is active when there is no end date', () {
      final status = WarrantyStatus.fromDates(DateTime(2020, 1, 1), null);

      expect(status, WarrantyStatus.active);
    });

    test('is active when the start date is missing but not expired', () {
      final status = WarrantyStatus.fromDates(
        null,
        DateTime(2100, 1, 1),
        DateTime(2026, 6, 15),
      );

      expect(status, WarrantyStatus.active);
    });

    test('is expired when the start date is missing and the end passed', () {
      final status = WarrantyStatus.fromDates(
        null,
        DateTime(2025, 1, 1),
        DateTime(2026, 6, 15),
      );

      expect(status, WarrantyStatus.expired);
    });
  });
}
