import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';

void main() {
  group('ReminderSettings', () {
    test('defaults to disabled with a 30-day lead time', () {
      final settings = ReminderSettings();

      expect(settings.enabled, isFalse);
      expect(settings.leadDays, 30);
    });

    test('keeps a supported lead time', () {
      final settings = ReminderSettings(enabled: true, leadDays: 7);

      expect(settings.enabled, isTrue);
      expect(settings.leadDays, 7);
    });

    test('falls back to the default for an unknown lead time', () {
      expect(
        ReminderSettings(enabled: true, leadDays: 0).leadDays,
        ReminderSettings.defaultLeadDays,
      );
      expect(
        ReminderSettings(leadDays: 45).leadDays,
        ReminderSettings.defaultLeadDays,
      );
    });

    test('copyWith keeps values that are not provided', () {
      final settings = ReminderSettings(enabled: true, leadDays: 14);

      final updated = settings.copyWith(enabled: false);
      final withLeadDays = settings.copyWith(leadDays: 3);

      expect(updated.enabled, isFalse);
      expect(updated.leadDays, 14);
      expect(withLeadDays.enabled, isTrue);
      expect(withLeadDays.leadDays, 3);
    });
  });
}
