import '../entities/reminder_settings.dart';

abstract class ReminderSettingsRepository {
  Future<ReminderSettings> load();

  Future<void> save(ReminderSettings settings);
}
