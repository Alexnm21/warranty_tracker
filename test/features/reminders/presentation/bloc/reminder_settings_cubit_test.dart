import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:warranty_tracker/features/reminders/presentation/bloc/reminder_settings_cubit.dart';
import 'package:warranty_tracker/features/reminders/presentation/bloc/reminder_settings_state.dart';

import '../fakes/fake_reminder_scheduler.dart';
import '../fakes/fake_reminder_settings_repository.dart';
import '../fakes/fake_warranty_notification_gateway.dart';

void main() {
  late FakeReminderSettingsRepository repository;
  late FakeWarrantyNotificationGateway gateway;
  late FakeReminderScheduler scheduler;
  late ReminderSettingsCubit cubit;

  ReminderSettingsCubit createCubit([ReminderSettings? settings]) {
    repository = FakeReminderSettingsRepository(settings);
    gateway = FakeWarrantyNotificationGateway();
    scheduler = FakeReminderScheduler();
    return ReminderSettingsCubit(
      settingsRepository: repository,
      gateway: gateway,
      scheduler: scheduler,
    );
  }

  setUp(() {
    cubit = createCubit();
  });

  tearDown(() => cubit.close());

  group('load', () {
    test('starts in the loading state', () {
      expect(cubit.state.status, ReminderSettingsStatus.loading);
      expect(cubit.state.settings, isNull);
    });

    test('loads settings and permission', () async {
      await cubit.load();

      expect(cubit.state.status, ReminderSettingsStatus.ready);
      expect(cubit.state.settings?.enabled, isFalse);
      expect(cubit.state.settings?.leadDays, ReminderSettings.defaultLeadDays);
      expect(scheduler.syncCount, 0);
    });

    test(
      'reports blocked when reminders are enabled without permission',
      () async {
        cubit = createCubit(ReminderSettings(enabled: true, leadDays: 7));
        gateway.permission = false;

        await cubit.load();

        expect(cubit.state.status, ReminderSettingsStatus.permissionBlocked);
        expect(cubit.state.settings?.enabled, isTrue);
      },
    );

    test('emits an error when the repository fails', () async {
      repository.throwOnLoad = true;

      await cubit.load();

      expect(cubit.state.status, ReminderSettingsStatus.error);
      expect(cubit.state.errorKey, 'settings.reminders.error.load');
    });
  });

  group('setEnabled', () {
    test('requests permission, saves and syncs when granted', () async {
      await cubit.load();

      await cubit.setEnabled(true);

      expect(gateway.permissionRequests, 1);
      expect(repository.saves.single.enabled, isTrue);
      expect(scheduler.syncCount, 1);
      expect(cubit.state.status, ReminderSettingsStatus.ready);
      expect(cubit.state.settings?.enabled, isTrue);
    });

    test('blocks without saving when permission is denied', () async {
      await cubit.load();
      gateway.requestResult = false;

      await cubit.setEnabled(true);

      expect(repository.saves, isEmpty);
      expect(scheduler.syncCount, 0);
      expect(cubit.state.status, ReminderSettingsStatus.permissionBlocked);
      expect(cubit.state.settings?.enabled, isFalse);
    });

    test('disabling saves and resyncs without asking for permission', () async {
      cubit = createCubit(ReminderSettings(enabled: true, leadDays: 7));
      await cubit.load();

      await cubit.setEnabled(false);

      expect(gateway.permissionRequests, 0);
      expect(repository.saves.single.enabled, isFalse);
      expect(scheduler.syncCount, 1);
      expect(cubit.state.settings?.enabled, isFalse);
    });
  });

  group('setLeadDays', () {
    test('saves the new lead time and syncs', () async {
      await cubit.load();

      await cubit.setLeadDays(14);

      expect(repository.saves.single.leadDays, 14);
      expect(scheduler.syncCount, 1);
      expect(cubit.state.settings?.leadDays, 14);
    });

    test('ignores the current value', () async {
      await cubit.load();

      await cubit.setLeadDays(ReminderSettings.defaultLeadDays);

      expect(repository.saves, isEmpty);
      expect(scheduler.syncCount, 0);
    });
  });

  group('errors and permission changes', () {
    test('keeps the previous settings when saving fails', () async {
      await cubit.load();
      repository.throwOnSave = true;

      await cubit.setLeadDays(7);

      expect(cubit.state.status, ReminderSettingsStatus.error);
      expect(cubit.state.errorKey, 'settings.reminders.error.save');
      expect(cubit.state.settings?.leadDays, ReminderSettings.defaultLeadDays);
    });

    test('clears a previous error on the next successful change', () async {
      await cubit.load();
      repository.throwOnSave = true;
      await cubit.setLeadDays(7);
      repository.throwOnSave = false;

      await cubit.setLeadDays(14);

      expect(cubit.state.status, ReminderSettingsStatus.ready);
      expect(cubit.state.errorKey, isNull);
    });

    test(
      'refreshPermission blocks an enabled setup after permission is lost',
      () async {
        cubit = createCubit(ReminderSettings(enabled: true, leadDays: 7));
        await cubit.load();
        gateway.permission = false;

        await cubit.refreshPermission();

        expect(cubit.state.status, ReminderSettingsStatus.permissionBlocked);
      },
    );

    test('refreshPermission resyncs when permission is restored', () async {
      cubit = createCubit(ReminderSettings(enabled: true, leadDays: 7));
      gateway.permission = false;
      await cubit.load();
      expect(cubit.state.status, ReminderSettingsStatus.permissionBlocked);
      gateway.permission = true;

      await cubit.refreshPermission();

      expect(cubit.state.status, ReminderSettingsStatus.ready);
      expect(scheduler.syncCount, 1);
    });

    test(
      'openSystemSettings opens the OS screen and refreshes permission',
      () async {
        await cubit.load();

        await cubit.openSystemSettings();

        expect(gateway.settingsOpenings, 1);
        expect(cubit.state.status, ReminderSettingsStatus.ready);
      },
    );
  });
}
