import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [child] inside a localized [MaterialApp] using the app's translations
/// and the same localization delegates as the real app.
///
/// Needed by widget tests for components that call `.tr()` or format dates:
/// `GlobalMaterialLocalizations` (included in `context.localizationDelegates`)
/// initializes `intl`'s date symbols.
Future<void> pumpLocalized(WidgetTester tester, Widget child) async {
  if (!_initialized) {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    _initialized = true;
  }

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  await tester.pumpAndSettle();
}

bool _initialized = false;
