import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_type.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/warranty_reminder.dart';
import 'package:warranty_tracker/features/reminders/domain/services/warranty_reminder_planner.dart';

void main() {
  const planner = WarrantyReminderPlanner();
  final enabledSettings = ReminderSettings(enabled: true, leadDays: 30);
  final now = DateTime(2026, 1, 1, 8);

  Product product(int id, DateTime endDate) {
    return Product(id: id, name: 'Laptop', warrantyEndDate: endDate);
  }

  List<WarrantyReminder> planFor(
    List<Product> products, {
    ReminderSettings? settings,
    DateTime? nowValue,
  }) {
    return planner.plan(
      products: products,
      settings: settings ?? enabledSettings,
      now: nowValue ?? now,
    );
  }

  group('WarrantyReminderPlanner.plan', () {
    test('returns nothing when reminders are disabled', () {
      final plan = planFor([
        product(1, DateTime(2026, 2, 1)),
      ], settings: ReminderSettings());

      expect(plan, isEmpty);
    });

    test('skips products without an id or an end date', () {
      final plan = planFor([
        Product(id: 1, name: 'No end date'),
        Product(name: 'Unsaved', warrantyEndDate: DateTime(2026, 2, 1)),
      ]);

      expect(plan, isEmpty);
    });

    test('plans both events at 09:00 with stable ids across months', () {
      final plan = planFor([product(1, DateTime(2026, 2, 1))]);

      expect(plan.map((reminder) => reminder.type), [
        ReminderType.approaching,
        ReminderType.expiration,
      ]);
      expect(plan.map((reminder) => reminder.notificationId), [2, 3]);
      expect(plan.map((reminder) => reminder.scheduledAt), [
        DateTime(2026, 1, 2, 9),
        DateTime(2026, 2, 1, 9),
      ]);
      expect(plan.every((reminder) => reminder.productId == 1), isTrue);
      expect(
        plan.every((reminder) => reminder.productName == 'Laptop'),
        isTrue,
      );
    });

    test('plans only the expiration when the end date is today', () {
      final plan = planFor([
        product(1, DateTime(2026, 1, 10)),
      ], nowValue: DateTime(2026, 1, 10, 8));

      expect(plan, hasLength(1));
      expect(plan.single.type, ReminderType.expiration);
      expect(plan.single.scheduledAt, DateTime(2026, 1, 10, 9));
    });

    test('skips events whose end date has passed', () {
      final plan = planFor([product(1, DateTime(2025, 12, 31))]);

      expect(plan, isEmpty);
    });

    test('skips an event scheduled exactly at now but keeps later ones', () {
      final products = [product(1, DateTime(2026, 1, 3))];
      final oneDaySettings = ReminderSettings(enabled: true, leadDays: 1);

      final atBoundary = planFor(
        products,
        settings: oneDaySettings,
        nowValue: DateTime(2026, 1, 2, 9),
      );
      final beforeBoundary = planFor(
        products,
        settings: oneDaySettings,
        nowValue: DateTime(2026, 1, 2, 8, 59),
      );

      expect(atBoundary.map((reminder) => reminder.type), [
        ReminderType.expiration,
      ]);
      expect(beforeBoundary.map((reminder) => reminder.type), [
        ReminderType.approaching,
        ReminderType.expiration,
      ]);
    });

    test('produces deterministic, duplicate-free ids', () {
      final products = [
        product(1, DateTime(2026, 3, 1)),
        product(2, DateTime(2026, 3, 2)),
        product(1, DateTime(2026, 3, 1)),
      ];

      final first = planFor(products);
      final second = planFor(products);

      List<List<Object>> signature(List<WarrantyReminder> reminders) {
        return reminders
            .map(
              (reminder) => [
                reminder.notificationId,
                reminder.productId,
                reminder.scheduledAt,
                reminder.type,
              ],
            )
            .toList();
      }

      expect(signature(second), signature(first));
      final ids = first.map((reminder) => reminder.notificationId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('caps the plan at the soonest 60 events in date order', () {
      final products = List<Product>.generate(
        61,
        (index) => product(index + 1, DateTime(2026, 2, 1 + index)),
      );

      final plan = planFor(products);

      expect(plan, hasLength(WarrantyReminderPlanner.maxReminders));
      expect(plan.first.scheduledAt, DateTime(2026, 1, 2, 9));
      for (var index = 1; index < plan.length; index++) {
        expect(
          plan[index].scheduledAt.isBefore(plan[index - 1].scheduledAt),
          isFalse,
        );
      }
      final ids = plan.map((reminder) => reminder.notificationId).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
