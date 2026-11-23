import 'dart:io';

import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:warranty_tracker/app/app.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/documents/data/services/document_file_storage.dart';
import 'package:warranty_tracker/features/documents/data/services/document_importer.dart';
import 'package:warranty_tracker/features/documents/domain/repositories/document_repository.dart';
import 'package:warranty_tracker/features/products/domain/repositories/product_repository.dart';
import 'package:warranty_tracker/features/products/presentation/pages/product_detail_page.dart';
import 'package:warranty_tracker/features/products/presentation/widgets/warranty_document_tile.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(getIt.reset);

  testWidgets('attach a document, view it and delete it from the detail', (
    tester,
  ) async {
    // Clear any locale saved by an earlier run: the test asserts English text.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final tempDirectory = await Directory.systemTemp.createTemp(
      'warranty_documents_e2e',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final source = File('${tempDirectory.path}/receipt.pdf');
    await source.writeAsString('%PDF-1.4 warranty test document');

    // In-memory database so the flow is deterministic and no user data from
    // the simulator is touched.
    setupInjection(database: AppDatabase.forTesting(NativeDatabase.memory()));

    // Keep stored documents inside the test's temporary directory instead of
    // the simulator's application documents folder.
    getIt.unregister<DocumentFileStorage>();
    getIt.registerLazySingleton<DocumentFileStorage>(
      () => DocumentFileStorage(baseDirectory: tempDirectory),
    );

    // The real file picker is a native sheet that the test cannot drive, so
    // the importer keeps its real validation/staging logic but receives a
    // fixed source file.
    getIt.unregister<DocumentImporter>();
    getIt.registerLazySingleton<DocumentImporter>(
      () => DocumentImporter(
        storage: getIt<DocumentFileStorage>(),
        fileSelector: () async => [XFile(source.path)],
      ),
    );

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

    await tester.tap(inShell(find.text('Products')));
    await settle(tester);

    // Create the product with one staged document ----------------------
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    await tester.enterText(
      inForm(find.byType(TextField)).at(0),
      'Warranty phone',
    );
    await settle(tester);
    await pickToday(tester);
    await chooseOneYearWarranty(tester);

    final upload = inForm(find.widgetWithText(OutlinedButton, 'Upload'));
    await scrollListUntil(
      tester,
      list: inForm(find.byType(ListView)),
      target: upload,
    );
    await tester.tap(upload);

    // Importing shows an indeterminate progress indicator, so wait for the
    // staged tile instead of using `pumpAndSettle` while it is on screen.
    final stagedTile = inForm(find.text('receipt.pdf'));
    await pumpUntilFound(tester, stagedTile);
    await scrollListUntil(
      tester,
      list: inForm(find.byType(ListView)),
      target: stagedTile,
    );

    await submitForm(tester);
    expect(inList(find.text('Warranty phone')), findsOneWidget);

    // The detail shows the persisted document --------------------------
    await tester.tap(inList(find.text('Warranty phone')));
    await settle(tester);

    final detailList = find.descendant(
      of: find.byType(ProductDetailPage),
      matching: find.byType(ListView),
    );
    final documentTile = find.descendant(
      of: find.byType(WarrantyDocumentTile),
      matching: find.text('receipt.pdf'),
    );
    await scrollListUntil(tester, list: detailList, target: documentTile);

    final product = (await getIt<ProductRepository>().getAll()).single;
    final saved = (await getIt<DocumentRepository>().getByProduct(
      product.id!,
    )).single;
    // The repository already resolves the stored relative path to an absolute
    // one when mapping the row.
    final storedPath = saved.filePath;
    expect(await File(storedPath).exists(), isTrue);

    // Delete the document from the detail ------------------------------
    await tester.tap(
      find.descendant(
        of: find.byType(WarrantyDocumentTile),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await settle(tester);

    expect(find.text('Delete document'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);

    expect(find.text('receipt.pdf'), findsNothing);
    expect(find.text('No documents attached'), findsOneWidget);

    // Metadata and the stored file are both gone.
    expect(
      await getIt<DocumentRepository>().getByProduct(product.id!),
      isEmpty,
    );
    expect(await File(storedPath).exists(), isFalse);
  });
}
