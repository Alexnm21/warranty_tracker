import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/pages/product_detail_page.dart';
import 'package:warranty_tracker/features/products/presentation/widgets/warranty_document_tile.dart';

import '../../../../helpers/pump_localized.dart';
import '../fakes/fake_document_opener.dart';
import '../fakes/fake_document_repository.dart';
import '../fakes/fake_product_repository.dart';

void main() {
  late FakeProductRepository productRepository;
  late FakeDocumentRepository documentRepository;
  late FakeDocumentOpener documentOpener;

  setUp(() {
    productRepository = FakeProductRepository([
      const Product(id: 1, name: 'Laptop'),
    ]);
    documentRepository = FakeDocumentRepository();
    documentOpener = FakeDocumentOpener();
    getIt.registerFactoryParam<ProductDetailCubit, int, void>(
      (productId, _) => ProductDetailCubit(
        repository: productRepository,
        documentRepository: documentRepository,
        documentOpener: documentOpener,
        productId: productId,
      ),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('shows the product documents', (tester) async {
    documentRepository = FakeDocumentRepository([_document()]);

    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('receipt.pdf'));

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(find.text('Pending save'), findsNothing);
  });

  testWidgets('shows the empty documents state', (tester) async {
    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('No documents attached'));

    expect(find.text('No documents attached'), findsOneWidget);
  });

  testWidgets('opens a document with the system viewer', (tester) async {
    documentRepository = FakeDocumentRepository([_document()]);

    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('receipt.pdf'));

    await tester.tap(find.text('receipt.pdf'));
    await tester.pump();

    expect(documentOpener.openedPaths, ['/persisted/1/receipt.pdf']);
  });

  testWidgets('shows an inline error when a document cannot be opened', (
    tester,
  ) async {
    documentRepository = FakeDocumentRepository([_document()]);
    documentOpener.openError = const DocumentOpenException(
      DocumentOpenFailure.noAppAvailable,
    );

    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('receipt.pdf'));

    await tester.tap(find.text('receipt.pdf'));
    await tester.pumpAndSettle();

    expect(
      find.text('No app is available to open this document'),
      findsOneWidget,
    );
  });

  testWidgets('deletes a document after confirmation', (tester) async {
    documentRepository = FakeDocumentRepository([_document()]);

    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('receipt.pdf'));

    await tester.tap(
      find.descendant(
        of: find.byType(WarrantyDocumentTile),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete document'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('receipt.pdf'), findsNothing);
    expect(find.text('No documents attached'), findsOneWidget);
    expect(documentRepository.documents, isEmpty);
  });

  testWidgets('keeps the document when deletion is cancelled', (tester) async {
    documentRepository = FakeDocumentRepository([_document()]);

    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('receipt.pdf'));

    await tester.tap(
      find.descendant(
        of: find.byType(WarrantyDocumentTile),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(documentRepository.documents, hasLength(1));
  });

  testWidgets('shows a load error and retries', (tester) async {
    documentRepository = FakeDocumentRepository([_document()])
      ..throwOnGetByProduct = true;

    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    await scrollTo(tester, find.text('Could not load documents'));

    expect(find.text('Retry'), findsOneWidget);

    documentRepository.throwOnGetByProduct = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('receipt.pdf'));
    expect(find.text('receipt.pdf'), findsOneWidget);
  });

  testWidgets('reloads product and documents when the route becomes current', (
    tester,
  ) async {
    await pumpLocalized(tester, const ProductDetailPage(productId: 1));
    expect(find.text('Laptop'), findsWidgets);

    await productRepository.update(
      const Product(id: 1, name: 'Updated Laptop'),
    );
    await documentRepository.add(1, _document());

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Edit')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Updated Laptop'), findsWidgets);
    await scrollTo(tester, find.text('receipt.pdf'));
    expect(find.text('receipt.pdf'), findsOneWidget);
  });
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
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

WarrantyDocument _document() {
  return WarrantyDocument(
    id: 1,
    productId: 1,
    fileName: 'receipt.pdf',
    filePath: '/persisted/1/receipt.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 10,
    source: DocumentSource.file,
    createdAt: DateTime(2026),
  );
}
