import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:warranty_tracker/features/reminders/presentation/bloc/reminder_settings_cubit.dart';
import 'package:warranty_tracker/features/settings/presentation/views/settings_view.dart';

import '../../../../helpers/pump_localized.dart';
import '../../../reminders/presentation/fakes/fake_reminder_scheduler.dart';
import '../../../reminders/presentation/fakes/fake_reminder_settings_repository.dart';
import '../../../reminders/presentation/fakes/fake_warranty_notification_gateway.dart';

void main() {
  late FakeReminderSettingsRepository repository;
  late FakeWarrantyNotificationGateway gateway;
  late FakeReminderScheduler scheduler;

  setUp(() {
    repository = FakeReminderSettingsRepository(ReminderSettings(leadDays: 14));
    gateway = FakeWarrantyNotificationGateway();
    scheduler = FakeReminderScheduler();
    getIt.registerFactory<ReminderSettingsCubit>(
      () => ReminderSettingsCubit(
        settingsRepository: repository,
        gateway: gateway,
        scheduler: scheduler,
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('loads and displays the reminder settings', (tester) async {
    await pumpLocalized(tester, const SettingsView());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Warranty reminders'), findsOneWidget);
    expect(find.text('Enable reminders'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('enabling reminders requests permission and syncs', (
    tester,
  ) async {
    await pumpLocalized(tester, const SettingsView());

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(gateway.permissionRequests, 1);
    expect(repository.saves.single.enabled, isTrue);
    expect(scheduler.syncCount, 1);
  });

  testWidgets('shows the denied state when permission is refused', (
    tester,
  ) async {
    gateway.requestResult = false;

    await pumpLocalized(tester, const SettingsView());
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Open system settings'), findsOneWidget);
    expect(repository.saves, isEmpty);
    expect(scheduler.syncCount, 0);
  });
}
