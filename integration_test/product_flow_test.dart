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
import 'package:warranty_tracker/features/products/presentation/pages/product_form_page.dart';
import 'package:warranty_tracker/features/products/presentation/pages/product_list_page.dart';

/// Scopes a finder to the shell bottom navigation bar.
Finder inShell(Finder child) =>
    find.descendant(of: find.byType(NavigationBar), matching: child);

/// Scopes a finder to the product form (create/edit) page.
Finder inForm(Finder child) =>
    find.descendant(of: find.byType(ProductFormPage), matching: child);

/// Scopes a finder to the product list page.
Finder inList(Finder child) =>
    find.descendant(of: find.byType(ProductListPage), matching: child);

/// Pumps until the tree stops changing, then waits briefly for pending async
/// work (localization assets, repository queries) and pumps again, so
/// assertions do not race against a real database read.
Future<void> settle(WidgetTester tester) async {
  const timeout = Duration(seconds: 30);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
  await Future<void>.delayed(const Duration(milliseconds: 150));
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
}

/// Opens the date picker for [label] and accepts the default (today) date.
Future<void> pickToday(WidgetTester tester, String label) async {
  // The tap lands on the field's floating label, which is not itself
  // hit-testable; the enclosing InkWell still receives it.
  await tester.tap(inForm(find.text(label)), warnIfMissed: false);
  await settle(tester);

  final confirm = find.widgetWithText(TextButton, 'OK');
  expect(
    confirm,
    findsOneWidget,
    reason: 'date picker did not open for $label',
  );
  await tester.tap(confirm);
  await settle(tester);
}

/// Scrolls the form to its Save button and taps it.
///
/// The button sits below the fold and a `ListView` does not build it until it
/// approaches the viewport, so it has to be scrolled into view first.
Future<void> submitForm(WidgetTester tester) async {
  final save = inForm(find.widgetWithText(FilledButton, 'Save'));
  for (var i = 0; i < 6 && save.evaluate().isEmpty; i++) {
    await tester.drag(inForm(find.byType(ListView)), const Offset(0, -300));
    await settle(tester);
  }
  expect(save, findsOneWidget, reason: 'Save button was not reachable');

  await tester.ensureVisible(save);
  await settle(tester);
  await tester.tap(save);
  await settle(tester);
}

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

    await pickToday(tester, 'Purchase date');
    await pickToday(tester, 'Warranty start');
    await pickToday(tester, 'Warranty end');

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
