import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/core/extensions/datetime_extensions.dart';
import 'package:warranty_tracker/core/widgets/option_selector_row.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_form_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/pages/product_form_page.dart';

import '../../../../helpers/pump_localized.dart';
import '../fakes/fake_document_importer.dart';
import '../fakes/fake_document_opener.dart';
import '../fakes/fake_document_repository.dart';
import '../fakes/fake_product_repository.dart';

void main() {
  late FakeProductRepository repository;
  late FakeDocumentRepository documentRepository;
  late FakeDocumentImporter documentImporter;
  late FakeDocumentOpener documentOpener;

  setUp(() {
    repository = FakeProductRepository();
    documentRepository = FakeDocumentRepository();
    documentImporter = FakeDocumentImporter();
    documentOpener = FakeDocumentOpener();
    getIt.registerFactoryParam<ProductFormCubit, int?, void>(
      (productId, _) => ProductFormCubit(
        repository: repository,
        documentRepository: documentRepository,
        documentImporter: documentImporter,
        documentOpener: documentOpener,
        productId: productId,
      ),
    );
  });

  tearDown(() => getIt.reset());

  /// Reads the currency shown as the prefix of the price field.
  String pricePrefix(WidgetTester tester) {
    final field = tester
        .widgetList<TextField>(find.byType(TextField))
        .firstWhere((field) => field.decoration?.prefix != null);
    return (field.decoration!.prefix! as Text).data!.trim();
  }

  OptionSelectorRow durationSelector(WidgetTester tester) {
    return tester.widget<OptionSelectorRow>(find.byType(OptionSelectorRow));
  }

  /// Scrolls the lazy form list until the warranty duration selector is built.
  Future<void> scrollToDurationSelector(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byType(OptionSelectorRow),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Product productWithDates(DateTime purchaseDate, DateTime warrantyEndDate) {
    return Product(
      id: 1,
      name: 'Laptop',
      purchaseDate: purchaseDate,
      warrantyEndDate: warrantyEndDate,
      createdAt: purchaseDate,
      updatedAt: purchaseDate,
    );
  }

  testWidgets('shows the default currency in the dropdown and the price', (
    tester,
  ) async {
    await pumpLocalized(tester, const ProductFormPage());

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(pricePrefix(tester), 'EUR');
  });

  testWidgets('updates the price prefix when another currency is selected', (
    tester,
  ) async {
    await pumpLocalized(tester, const ProductFormPage());

    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    expect(pricePrefix(tester), 'USD');
  });

  testWidgets('selects one year by default when creating', (tester) async {
    await pumpLocalized(tester, const ProductFormPage());
    await scrollToDurationSelector(tester);

    final selector = durationSelector(tester);
    expect(selector.selectedOption, selector.options.first);
  });

  testWidgets('preselects the custom option when editing a custom end date', (
    tester,
  ) async {
    repository = FakeProductRepository([
      productWithDates(DateTime(2025, 1, 1), DateTime(2025, 3, 15)),
    ]);

    await pumpLocalized(tester, const ProductFormPage(productId: 1));
    await scrollToDurationSelector(tester);

    final selector = durationSelector(tester);
    expect(selector.selectedOption, selector.options.last);
  });

  testWidgets('preselects the matching duration when editing', (tester) async {
    repository = FakeProductRepository([
      productWithDates(DateTime(2025, 1, 1), DateTime(2027, 1, 1)),
    ]);

    await pumpLocalized(tester, const ProductFormPage(productId: 1));
    await scrollToDurationSelector(tester);

    final selector = durationSelector(tester);
    expect(selector.selectedOption, selector.options[1]);
  });

  testWidgets('opens the date picker when choosing custom', (tester) async {
    await pumpLocalized(tester, const ProductFormPage());

    await scrollToDurationSelector(tester);
    final selector = durationSelector(tester);
    await tester.tap(find.text(selector.options.last));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });

  testWidgets('keeps the previous option when the custom picker is cancelled', (
    tester,
  ) async {
    await pumpLocalized(tester, const ProductFormPage());

    await scrollToDurationSelector(tester);
    final selector = durationSelector(tester);
    final previousOption = selector.selectedOption;

    await tester.tap(find.text(selector.options.last));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsNothing);
    expect(durationSelector(tester).selectedOption, previousOption);
  });

  testWidgets('updates the end date when a custom date is confirmed', (
    tester,
  ) async {
    await pumpLocalized(tester, const ProductFormPage());

    await scrollToDurationSelector(tester);
    final selector = durationSelector(tester);
    await tester.tap(find.text(selector.options.last));
    await tester.pumpAndSettle();

    final calendar = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    final initialDate = calendar.initialDate!;
    final targetDay = initialDate.day == 15 ? 16 : 15;
    final targetDate = DateTime(initialDate.year, initialDate.month, targetDay);

    await tester.tap(
      find
          .descendant(
            of: find.byType(CalendarDatePicker),
            matching: find.text('$targetDay'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text(targetDate.dateString), findsOneWidget);
    expect(durationSelector(tester).selectedOption, selector.options.last);
  });
}
