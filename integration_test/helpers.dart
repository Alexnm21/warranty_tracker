import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Pumps frames until [finder] matches, letting real async work (file copies,
/// database writes) finish in the meantime.
///
/// Prefer this over [settle] while an indeterminate progress indicator is on
/// screen: that animation schedules frames indefinitely, so `pumpAndSettle`
/// would never settle.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Drags [list] until [target] is built, then scrolls it into view.
///
/// Necessary because lazy lists only build the items near the viewport.
Future<void> scrollListUntil(
  WidgetTester tester, {
  required Finder list,
  required Finder target,
  int maxDrags = 8,
  double dy = -300,
}) async {
  for (var i = 0; i < maxDrags && target.evaluate().isEmpty; i++) {
    await tester.drag(list, Offset(0, dy));
    await settle(tester);
  }

  expect(target, findsOneWidget, reason: '$target was not reachable');

  await tester.ensureVisible(target);
  await settle(tester);
}

/// Opens the purchase date picker and accepts the default (today) date.
Future<void> pickToday(WidgetTester tester) async {
  // Tap the calendar icon inside the field's InkWell: the visible label is a
  // separate, non hit-testable Text. This also avoids matching the dialog's
  // own title once the picker is open.
  final field = inForm(find.byIcon(Icons.calendar_today));
  await tester.ensureVisible(field);
  await settle(tester);
  await tester.tap(field);
  await settle(tester);

  expect(
    find.byType(CalendarDatePicker),
    findsOneWidget,
    reason: 'purchase date picker did not open',
  );

  final confirm = find.widgetWithText(FilledButton, 'Confirm');
  expect(confirm, findsOneWidget);
  await tester.tap(confirm);
  await settle(tester);
}

/// Selects the one-year warranty duration so the end date is calculated.
Future<void> chooseOneYearWarranty(WidgetTester tester) async {
  final oneYear = inForm(find.text('1 year'));
  await tester.ensureVisible(oneYear);
  await settle(tester);
  await tester.tap(oneYear);
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
