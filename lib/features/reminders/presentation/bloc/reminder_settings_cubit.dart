import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/warranty_notification_gateway.dart';
import '../../domain/entities/reminder_settings.dart';
import '../../domain/repositories/reminder_settings_repository.dart';
import '../../domain/services/reminder_scheduler.dart';
import 'reminder_settings_state.dart';

/// Manages reminder preferences and the notification permission state.
///
/// Permission is requested only from [setEnabled], which is called by an
/// explicit user action. Saving a change always triggers a scheduler sync so
/// the pending notifications match the stored settings.
class ReminderSettingsCubit extends Cubit<ReminderSettingsState> {
  ReminderSettingsCubit({
    required ReminderSettingsRepository settingsRepository,
    required WarrantyNotificationGateway gateway,
    required ReminderScheduler scheduler,
  }) : _settingsRepository = settingsRepository,
       _gateway = gateway,
       _scheduler = scheduler,
       super(
         const ReminderSettingsState(status: ReminderSettingsStatus.loading),
       );

  final ReminderSettingsRepository _settingsRepository;
  final WarrantyNotificationGateway _gateway;
  final ReminderScheduler _scheduler;

  /// Loads stored preferences and the current permission state.
  Future<void> load() async {
    emit(const ReminderSettingsState(status: ReminderSettingsStatus.loading));

    try {
      final settings = await _settingsRepository.load();
      final hasPermission = await _gateway.hasPermission();
      if (isClosed) {
        return;
      }

      emit(
        ReminderSettingsState(
          status: settings.enabled && !hasPermission
              ? ReminderSettingsStatus.permissionBlocked
              : ReminderSettingsStatus.ready,
          settings: settings,
        ),
      );
    } on Exception {
      if (!isClosed) {
        emit(
          const ReminderSettingsState(
            status: ReminderSettingsStatus.error,
            errorKey: 'settings.reminders.error.load',
          ),
        );
      }
    }
  }

  /// Enables or disables reminders.
  ///
  /// A denied permission leaves `enabled` unchanged and shows the blocked
  /// state, so a preference is never stored without the permission to honour
  /// it.
  Future<void> setEnabled(bool value) async {
    final current = state.settings;
    if (current == null || state.status == ReminderSettingsStatus.saving) {
      return;
    }

    if (!value) {
      await _persist(current.copyWith(enabled: false));
      return;
    }

    emit(
      state.copyWith(status: ReminderSettingsStatus.saving, clearError: true),
    );
    bool granted;
    try {
      granted = await _gateway.requestPermission();
    } on Exception {
      granted = false;
    }
    if (isClosed) {
      return;
    }
    if (!granted) {
      emit(state.copyWith(status: ReminderSettingsStatus.permissionBlocked));
      return;
    }

    await _persist(current.copyWith(enabled: true));
  }

  /// Changes the lead time used for the approaching reminder.
  Future<void> setLeadDays(int days) async {
    final current = state.settings;
    if (current == null ||
        current.leadDays == days ||
        state.status == ReminderSettingsStatus.saving) {
      return;
    }

    await _persist(current.copyWith(leadDays: days));
  }

  /// Re-checks permission, for example when the settings route becomes current
  /// again after visiting the system settings.
  Future<void> refreshPermission() async {
    final settings = state.settings;
    if (settings == null || state.status == ReminderSettingsStatus.loading) {
      return;
    }

    try {
      final hasPermission = await _gateway.hasPermission();
      if (isClosed) {
        return;
      }

      if (!hasPermission && settings.enabled) {
        emit(
          state.copyWith(
            status: ReminderSettingsStatus.permissionBlocked,
            clearError: true,
          ),
        );
        return;
      }

      final wasBlocked =
          state.status == ReminderSettingsStatus.permissionBlocked;
      emit(
        state.copyWith(status: ReminderSettingsStatus.ready, clearError: true),
      );

      if (wasBlocked && settings.enabled && hasPermission) {
        await _scheduler.sync();
      }
    } on Exception {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ReminderSettingsStatus.error,
            errorKey: 'settings.reminders.error.permission',
          ),
        );
      }
    }
  }

  /// Opens the OS notification settings and refreshes the permission state.
  Future<void> openSystemSettings() async {
    try {
      await _gateway.openSystemNotificationSettings();
    } on Exception catch (error) {
      // The user may still change the setting manually, so keep going.
      debugPrint(
        'ReminderSettingsCubit: could not open notification settings: $error',
      );
    }
    await refreshPermission();
  }

  Future<void> _persist(
    ReminderSettings settings, {
    String errorKey = 'settings.reminders.error.save',
  }) async {
    emit(
      state.copyWith(status: ReminderSettingsStatus.saving, clearError: true),
    );

    try {
      await _settingsRepository.save(settings);
      await _scheduler.sync();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ReminderSettingsStatus.ready,
            settings: settings,
          ),
        );
      }
    } on Exception {
      if (!isClosed) {
        // Keep the previous settings: the UI must not show a value that was
        // not persisted.
        emit(
          state.copyWith(
            status: ReminderSettingsStatus.error,
            errorKey: errorKey,
          ),
        );
      }
    }
  }
}
