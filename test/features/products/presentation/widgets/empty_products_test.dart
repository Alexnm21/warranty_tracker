import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/presentation/widgets/empty_products.dart';

import '../../../../helpers/pump_localized.dart';

void main() {
  testWidgets('shows the empty message and add button', (tester) async {
    await pumpLocalized(tester, EmptyProducts(onAdd: () {}));

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Add product'), findsOneWidget);
  });

  testWidgets('calls onAdd when the button is pressed', (tester) async {
    var added = false;

    await pumpLocalized(tester, EmptyProducts(onAdd: () => added = true));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(added, isTrue);
  });
}
