import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:warranty_tracker/app/app.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/settings/presentation/views/settings_view.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(getIt.reset);

  testWidgets('settings reminders smoke: section loads without enabling', (
    tester,
  ) async {
    // Clear any locale saved by an earlier run: easy_localization ignores
    // `startLocale` when a saved locale exists, and this test asserts on
    // English strings.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    // In-memory database so the flow is deterministic and no user data from
    // the simulator is touched.
    setupInjection(database: AppDatabase.forTesting(NativeDatabase.memory()));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: const App(),
      ),
    );
    await settle(tester);

    // The app opens on Home; move to the Settings tab.
    await tester.tap(inShell(find.text('Settings')));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(SettingsView),
        matching: find.text('Settings'),
      ),
      findsOneWidget,
    );
    expect(find.text('Warranty reminders'), findsOneWidget);
    expect(
      find.text(
        'Get a notification before a warranty ends and on its expiration date.',
      ),
      findsOneWidget,
    );
    expect(find.text('Enable reminders'), findsOneWidget);

    // Deterministic smoke: do not toggle, so no permission prompt is triggered.
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
