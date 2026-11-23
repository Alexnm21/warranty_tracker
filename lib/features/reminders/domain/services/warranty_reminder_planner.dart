import '../../../products/domain/entities/product.dart';
import '../entities/reminder_settings.dart';
import '../entities/reminder_type.dart';
import '../entities/warranty_reminder.dart';

class WarrantyReminderPlanner {
  const WarrantyReminderPlanner();

  /// Leaves room under iOS's 64 pending notification limit for other app
  /// notifications.
  static const int maxReminders = 60;
  static const int _reminderHour = 9;
  // One slot per ReminderType: approaching and expiration.
  static const int _idsPerProduct = 2;

  List<WarrantyReminder> plan({
    required List<Product> products,
    required ReminderSettings settings,
    required DateTime now,
  }) {
    if (!settings.enabled) {
      return const <WarrantyReminder>[];
    }

    final reminders = <WarrantyReminder>[];
    final seenIds = <int>{};
    for (final product in products) {
      final endDate = product.warrantyEndDate;
      final productId = product.id;
      if (endDate == null || productId == null) {
        continue;
      }

      // Day overflow is normalized by DateTime, so calendar arithmetic stays
      // correct across months and daylight saving changes.
      final approachingDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day - settings.leadDays,
      );
      final expirationAt = _atReminderTime(endDate);
      final approachingAt = _atReminderTime(approachingDate);

      final approaching = _reminder(
        product,
        productId,
        approachingAt,
        ReminderType.approaching,
      );
      final expiration = _reminder(
        product,
        productId,
        expirationAt,
        ReminderType.expiration,
      );

      // The settings validator excludes a zero lead time; keep the planner
      // safe from two notifications on the same day if that ever changes.
      if (approachingAt != expirationAt &&
          _isFuture(approachingAt, now) &&
          seenIds.add(approaching.notificationId)) {
        reminders.add(approaching);
      }
      if (_isFuture(expirationAt, now) &&
          seenIds.add(expiration.notificationId)) {
        reminders.add(expiration);
      }
    }

    reminders.sort((a, b) {
      final byDate = a.scheduledAt.compareTo(b.scheduledAt);
      return byDate != 0
          ? byDate
          : a.notificationId.compareTo(b.notificationId);
    });

    return reminders.take(maxReminders).toList(growable: false);
  }

  static DateTime _atReminderTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, _reminderHour);
  }

  static bool _isFuture(DateTime scheduledAt, DateTime now) {
    return scheduledAt.isAfter(now);
  }

  static WarrantyReminder _reminder(
    Product product,
    int productId,
    DateTime scheduledAt,
    ReminderType type,
  ) {
    return WarrantyReminder(
      // SQLite ids are positive, so this is stable and collision-free.
      notificationId: productId * _idsPerProduct + type.index,
      productId: productId,
      productName: product.name,
      scheduledAt: scheduledAt,
      type: type,
    );
  }
}
