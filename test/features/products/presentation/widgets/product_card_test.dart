import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/widgets/product_card.dart';

import '../../../../helpers/pump_localized.dart';

void main() {
  testWidgets('shows the name, subtitle and warranty status', (tester) async {
    await pumpLocalized(
      tester,
      ProductCard(
        product: Product(
          id: 1,
          name: 'Laptop',
          brand: 'Lenovo',
          model: 'ThinkPad',
          warrantyEndDate: DateTime(2100, 1, 1),
        ),
      ),
    );

    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Lenovo · ThinkPad'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('calls onTap when pressed', (tester) async {
    var tapped = false;

    await pumpLocalized(
      tester,
      ProductCard(
        product: const Product(id: 1, name: 'Laptop'),
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
