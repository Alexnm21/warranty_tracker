import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:warranty_tracker/app/app.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/products/presentation/pages/product_detail_page.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(getIt.reset);

  testWidgets('create, view, edit, search and delete a product', (
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

    // The app opens on Home; move to the Products tab.
    await tester.tap(inShell(find.text('Products')));
    await settle(tester);
    expect(find.text('No products yet'), findsOneWidget);

    // Create ------------------------------------------------------------
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('New product'), findsOneWidget);

    await tester.enterText(
      inForm(find.byType(TextField)).at(0),
      'iPhone 17 Pro',
    );
    await settle(tester);

    await pickToday(tester);
    await chooseOneYearWarranty(tester);

    await submitForm(tester);
    // Back on the list with the new card.
    expect(inList(find.text('iPhone 17 Pro')), findsOneWidget);
    expect(inList(find.text('Active')), findsOneWidget);

    // Detail ------------------------------------------------------------
    await tester.tap(inList(find.text('iPhone 17 Pro')));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byType(ProductDetailPage),
        matching: find.text('iPhone 17 Pro'),
      ),
      findsWidgets,
    );
    expect(find.text('Warranty'), findsOneWidget);

    // Edit --------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);
    expect(find.text('Edit product'), findsOneWidget);

    await tester.enterText(
      inForm(find.byType(TextField)).at(0),
      'iPhone 17 Pro Max',
    );
    await submitForm(tester);

    expect(inList(find.text('iPhone 17 Pro')), findsNothing);
    expect(inList(find.text('iPhone 17 Pro Max')), findsOneWidget);

    // Search ------------------------------------------------------------
    await tester.enterText(inList(find.byType(TextField)), 'nope');
    await settle(tester);
    expect(find.text('No products found'), findsOneWidget);

    await tester.enterText(inList(find.byType(TextField)), 'iphone');
    await settle(tester);
    expect(inList(find.text('iPhone 17 Pro Max')), findsOneWidget);

    await tester.tap(inList(find.byIcon(Icons.clear)));
    await settle(tester);
    expect(inList(find.text('iPhone 17 Pro Max')), findsOneWidget);

    // Delete (swipe to delete + confirmation) ---------------------------
    await tester.fling(inList(find.byType(Card)), const Offset(-400, 0), 1000);
    await settle(tester);
    expect(find.text('Delete product'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    expect(find.text('No products yet'), findsOneWidget);
  });
}
