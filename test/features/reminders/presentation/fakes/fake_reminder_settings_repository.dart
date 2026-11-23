import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:warranty_tracker/features/reminders/domain/repositories/reminder_settings_repository.dart';

class FakeReminderSettingsRepository implements ReminderSettingsRepository {
  FakeReminderSettingsRepository([ReminderSettings? settings])
    : _settings = settings ?? ReminderSettings();

  ReminderSettings _settings;
  bool throwOnLoad = false;
  bool throwOnSave = false;
  final List<ReminderSettings> saves = [];

  @override
  Future<ReminderSettings> load() async {
    if (throwOnLoad) {
      throw Exception('load failed');
    }
    return _settings;
  }

  @override
  Future<void> save(ReminderSettings value) async {
    if (throwOnSave) {
      throw Exception('save failed');
    }
    saves.add(value);
    _settings = value;
  }
}
