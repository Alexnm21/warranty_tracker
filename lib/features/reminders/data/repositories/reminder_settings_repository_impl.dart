import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/reminder_settings_repository.dart';

class ReminderSettingsRepositoryImpl implements ReminderSettingsRepository {
  static const String _enabledKey = 'reminders.enabled';
  static const String _leadDaysKey = 'reminders.lead_days';

  @override
  Future<ReminderSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: preferences.getBool(_enabledKey) ?? false,
      leadDays:
          preferences.getInt(_leadDaysKey) ?? ReminderSettings.defaultLeadDays,
    );
  }

  @override
  Future<void> save(ReminderSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, settings.enabled);
    await preferences.setInt(_leadDaysKey, settings.leadDays);
  }
}
