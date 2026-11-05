import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/products/presentation/widgets/product_documents_section.dart';

import '../../../../helpers/pump_localized.dart';

void main() {
  testWidgets('shows the empty state and the document actions', (tester) async {
    await pumpLocalized(tester, _buildSection());

    expect(find.text('No documents attached'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
  });

  testWidgets('calls the scan action', (tester) async {
    var scans = 0;
    await pumpLocalized(
      tester,
      _buildSection(
        onScan: () async {
          scans++;
        },
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pump();

    expect(scans, 1);
  });

  testWidgets('shows a staged document and opens it when tapped', (
    tester,
  ) async {
    final document = _document();
    WarrantyDocument? opened;

    await pumpLocalized(
      tester,
      _buildSection(
        documents: [document],
        onOpen: (document) async {
          opened = document;
        },
      ),
    );

    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(find.text('Pending save'), findsOneWidget);

    await tester.tap(find.text('receipt.pdf'));
    await tester.pump();

    expect(opened, document);
  });

  testWidgets('does not mark a persisted document as pending', (tester) async {
    await pumpLocalized(
      tester,
      _buildSection(documents: [_document(persisted: true)]),
    );

    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(find.text('Pending save'), findsNothing);
  });

  testWidgets('shows document errors', (tester) async {
    await pumpLocalized(
      tester,
      _buildSection(error: 'products.form.documents.error.fileTooLarge'),
    );

    expect(find.text('The file must be 25 MB or smaller'), findsOneWidget);
  });

  testWidgets('disables actions while the form is busy', (tester) async {
    await pumpLocalized(tester, _buildSection(isBusy: true));

    final scanButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Scan'),
    );
    expect(scanButton.onPressed, isNull);
  });

  testWidgets('asks for confirmation before removing a document', (
    tester,
  ) async {
    final document = _document();
    WarrantyDocument? removed;

    await pumpLocalized(
      tester,
      _buildSection(
        documents: [document],
        onRemove: (document) async {
          removed = document;
        },
      ),
    );

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Remove document'), findsOneWidget);
    expect(
      find.text('Remove "receipt.pdf"? The file will be discarded.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(removed, document);
  });

  testWidgets('keeps the document when removal is cancelled', (tester) async {
    WarrantyDocument? removed;

    await pumpLocalized(
      tester,
      _buildSection(
        documents: [_document()],
        onRemove: (document) async {
          removed = document;
        },
      ),
    );

    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(removed, isNull);
  });
}

Widget _buildSection({
  List<WarrantyDocument> documents = const [],
  bool isImporting = false,
  bool isBusy = false,
  String? error,
  Future<void> Function()? onScan,
  Future<void> Function()? onUpload,
  Future<void> Function()? onTakePhoto,
  Future<void> Function(WarrantyDocument)? onOpen,
  Future<void> Function(WarrantyDocument)? onRemove,
}) {
  return ProductDocumentsSection(
    documents: documents,
    isImporting: isImporting,
    isBusy: isBusy,
    error: error,
    onScan: onScan ?? () async {},
    onUpload: onUpload ?? () async {},
    onTakePhoto: onTakePhoto ?? () async {},
    onOpen: onOpen ?? (_) async {},
    onRemove: onRemove ?? (_) async {},
  );
}

WarrantyDocument _document({bool persisted = false}) {
  return WarrantyDocument(
    id: persisted ? 1 : null,
    productId: persisted ? 1 : null,
    fileName: 'receipt.pdf',
    filePath: persisted ? '/documents/1/receipt.pdf' : '/staged/receipt.pdf',
    mimeType: 'application/pdf',
    sizeBytes: 10,
    source: DocumentSource.file,
    createdAt: persisted ? DateTime(2026) : null,
  );
}
