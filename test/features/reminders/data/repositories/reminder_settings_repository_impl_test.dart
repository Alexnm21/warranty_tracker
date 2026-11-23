import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warranty_tracker/features/reminders/data/repositories/reminder_settings_repository_impl.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = ReminderSettingsRepositoryImpl();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ReminderSettingsRepositoryImpl', () {
    test('returns defaults when nothing was stored', () async {
      final settings = await repository.load();

      expect(settings.enabled, isFalse);
      expect(settings.leadDays, ReminderSettings.defaultLeadDays);
    });

    test('loads stored values', () async {
      SharedPreferences.setMockInitialValues({
        'reminders.enabled': true,
        'reminders.lead_days': 7,
      });

      final settings = await repository.load();

      expect(settings.enabled, isTrue);
      expect(settings.leadDays, 7);
    });

    test('falls back to the default for an unknown stored lead time', () async {
      SharedPreferences.setMockInitialValues({
        'reminders.enabled': true,
        'reminders.lead_days': 45,
      });

      final settings = await repository.load();

      expect(settings.enabled, isTrue);
      expect(settings.leadDays, ReminderSettings.defaultLeadDays);
    });

    test('saves both values', () async {
      await repository.save(ReminderSettings(enabled: true, leadDays: 14));

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool('reminders.enabled'), isTrue);
      expect(preferences.getInt('reminders.lead_days'), 14);
    });
  });
}
