import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:warranty_tracker/features/reminders/presentation/bloc/reminder_settings_state.dart';
import 'package:warranty_tracker/features/reminders/presentation/widgets/reminder_settings_section.dart';

import '../../../../helpers/pump_localized.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    ReminderSettingsState state, {
    Future<void> Function(bool)? onEnabled,
    Future<void> Function(int)? onLeadDays,
    Future<void> Function()? onOpenSettings,
    Future<void> Function()? onRetry,
    Future<void> Function()? onDebugPrintPending,
    bool settle = true,
  }) {
    return pumpLocalized(
      tester,
      ReminderSettingsSection(
        state: state,
        onEnabledChanged: onEnabled ?? (value) async {},
        onLeadDaysChanged: onLeadDays ?? (days) async {},
        onOpenSystemSettings: onOpenSettings ?? () async {},
        onRetry: onRetry ?? () async {},
        onDebugPrintPending: onDebugPrintPending ?? () async {},
      ),
      settle: settle,
    );
  }

  ReminderSettingsState readyState([ReminderSettings? settings]) {
    return ReminderSettingsState(
      status: ReminderSettingsStatus.ready,
      settings: settings ?? ReminderSettings(leadDays: 7),
    );
  }

  testWidgets('shows the switch and the lead-time options', (tester) async {
    await pumpSection(tester, readyState());

    expect(find.text('Warranty reminders'), findsOneWidget);
    expect(find.text('Enable reminders'), findsOneWidget);
    expect(find.text('Notify before (days)'), findsOneWidget);
    for (final days in ReminderSettings.leadDaysOptions) {
      expect(find.text(days.toString()), findsOneWidget);
    }
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('reports a switch change through the callback', (tester) async {
    final enabledValues = <bool>[];

    await pumpSection(
      tester,
      readyState(),
      onEnabled: (value) async => enabledValues.add(value),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(enabledValues, [true]);
  });

  testWidgets('reports a lead-time change through the callback', (
    tester,
  ) async {
    final selectedDays = <int>[];

    await pumpSection(
      tester,
      readyState(),
      onLeadDays: (days) async => selectedDays.add(days),
    );

    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();

    expect(selectedDays, [14]);
  });

  testWidgets('shows the denied message and the system settings action', (
    tester,
  ) async {
    var opened = false;

    await pumpSection(
      tester,
      ReminderSettingsState(
        status: ReminderSettingsStatus.permissionBlocked,
        settings: ReminderSettings(enabled: true, leadDays: 7),
      ),
      onOpenSettings: () async => opened = true,
    );

    expect(
      find.text(
        'Notifications are blocked. Enable them in system settings to receive reminders.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open system settings'), findsOneWidget);
    expect(find.text('Notify before (days)'), findsNothing);

    await tester.tap(find.text('Open system settings'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('shows a saving indicator and disables the switch', (
    tester,
  ) async {
    await pumpSection(
      tester,
      ReminderSettingsState(
        status: ReminderSettingsStatus.saving,
        settings: ReminderSettings(leadDays: 7),
      ),
      settle: false,
    );

    expect(find.text('Saving…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('shows the error message and a retry action', (tester) async {
    var retried = false;

    await pumpSection(
      tester,
      ReminderSettingsState(
        status: ReminderSettingsStatus.error,
        settings: ReminderSettings(leadDays: 7),
        errorKey: 'settings.reminders.error.save',
      ),
      onRetry: () async => retried = true,
    );

    expect(find.text('Could not save reminder settings'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retried, isTrue);
  });
}
