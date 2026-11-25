import '../../domain/entities/reminder_settings.dart';

/// Lifecycle of the reminder settings screen.
enum ReminderSettingsStatus { loading, ready, saving, permissionBlocked, error }

/// State for the reminder settings screen.
///
/// [settings] is null until the first load completes; the UI only renders the
/// controls once it is available. [errorKey] is a localization key.
class ReminderSettingsState {
  const ReminderSettingsState({
    required this.status,
    this.settings,
    this.errorKey,
  });

  final ReminderSettingsStatus status;
  final ReminderSettings? settings;
  final String? errorKey;

  ReminderSettingsState copyWith({
    ReminderSettingsStatus? status,
    ReminderSettings? settings,
    String? errorKey,
    bool clearError = false,
  }) {
    return ReminderSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }
}
