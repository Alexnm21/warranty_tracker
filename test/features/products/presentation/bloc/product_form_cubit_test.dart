import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_form_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_form_state.dart';

import '../fakes/fake_document_importer.dart';
import '../fakes/fake_document_opener.dart';
import '../fakes/fake_document_repository.dart';
import '../fakes/fake_product_repository.dart';

void main() {
  final purchaseDate = DateTime(2026, 1, 5);
  final end = DateTime(2027, 1, 5);

  ProductFormData validData() => ProductFormData(
    name: 'Laptop',
    purchaseDate: purchaseDate,
    warrantyEndDate: end,
  );

  group('create mode', () {
    test('starts ready without loading', () async {
      final cubit = createCubit();

      expect(cubit.state.status, ProductFormStatus.ready);

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.ready);
    });

    test('saves a valid product', () async {
      final repository = FakeProductRepository();
      final cubit = createCubit(repository: repository);

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saved);
      expect(cubit.state.product?.id, isNotNull);
      expect(repository.products.single.name, 'Laptop');
    });

    test('converts the price to minor units and trims the currency', () async {
      final repository = FakeProductRepository();
      final cubit = createCubit(repository: repository);

      await cubit.save(
        validData().copyWithText(priceText: '899.99', currency: ' EUR '),
      );

      expect(repository.products.single.price, 89999);
      expect(repository.products.single.currency, 'EUR');
    });

    test('stores no price or currency when the price is empty', () async {
      final repository = FakeProductRepository();
      final cubit = createCubit(repository: repository);

      await cubit.save(validData().copyWithText(currency: 'EUR'));

      expect(repository.products.single.price, isNull);
      expect(repository.products.single.currency, isNull);
    });

    test('rejects an empty name', () async {
      final repository = FakeProductRepository();
      final cubit = createCubit(repository: repository);

      await cubit.save(validData().copyWithText(name: '   '));

      expect(cubit.state.errors[ProductFormField.name], isNotNull);
      expect(cubit.state.status, ProductFormStatus.ready);
      expect(repository.products, isEmpty);
    });

    test('requires the purchase and warranty dates', () async {
      final cubit = createCubit();

      await cubit.save(const ProductFormData(name: 'Laptop'));

      expect(cubit.state.errors[ProductFormField.purchaseDate], isNotNull);
      expect(cubit.state.errors[ProductFormField.warrantyEndDate], isNotNull);
    });

    test('rejects a warranty end before the purchase date', () async {
      final cubit = createCubit();

      await cubit.save(
        ProductFormData(
          name: 'Laptop',
          purchaseDate: purchaseDate,
          warrantyEndDate: DateTime(2025, 12, 31),
        ),
      );

      expect(
        cubit.state.errors[ProductFormField.warrantyEndDate],
        'products.form.error.warrantyEndBeforePurchase',
      );
    });

    test('rejects an invalid price', () async {
      final cubit = createCubit();

      await cubit.save(validData().copyWithText(priceText: 'abc'));

      expect(cubit.state.errors[ProductFormField.price], isNotNull);
    });

    test('rejects a negative price', () async {
      final cubit = createCubit();

      await cubit.save(validData().copyWithText(priceText: '-5'));

      expect(cubit.state.errors[ProductFormField.price], isNotNull);
    });

    test('requires a currency when a price is set', () async {
      final cubit = createCubit();

      await cubit.save(validData().copyWithText(priceText: '10'));

      expect(cubit.state.errors[ProductFormField.currency], isNotNull);
    });

    test('emits saveError when the repository fails', () async {
      final repository = FakeProductRepository()..throwOnCreate = true;
      final cubit = createCubit(repository: repository);

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saveError);
    });
  });

  group('edit mode', () {
    test('loads the product being edited', () async {
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final cubit = createCubit(repository: repository, productId: 1);

      expect(cubit.state.status, ProductFormStatus.loading);

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.ready);
      expect(cubit.state.product?.name, 'Laptop');
    });

    test('loads the product documents', () async {
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final documentRepository = FakeDocumentRepository([persistedDocument()]);
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        productId: 1,
      );

      await cubit.load();

      expect(cubit.state.documents, hasLength(1));
      expect(cubit.state.documents.single.fileName, 'receipt.pdf');
      expect(cubit.state.removedDocuments, isEmpty);
    });

    test('emits loadError when the product is missing', () async {
      final cubit = createCubit(productId: 99);

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.loadError);
    });

    test('emits loadError when documents cannot be loaded', () async {
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final documentRepository = FakeDocumentRepository()
        ..throwOnGetByProduct = true;
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        productId: 1,
      );

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.loadError);
    });

    test('updates the product and preserves id and createdAt', () async {
      final createdAt = DateTime(2025, 1, 1);
      final repository = FakeProductRepository([
        Product(
          id: 1,
          name: 'Laptop',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ]);
      final cubit = createCubit(repository: repository, productId: 1);
      await cubit.load();

      await cubit.save(validData().copyWithText(name: 'Renamed'));

      final saved = repository.products.single;
      expect(saved.id, 1);
      expect(saved.name, 'Renamed');
      expect(saved.createdAt, createdAt);
    });
  });

  group('document import', () {
    test('adds scanned documents', () async {
      final documentImporter = FakeDocumentImporter()
        ..scannedDocuments = [
          stagedDocument(fileName: 'scan.pdf', source: DocumentSource.scan),
        ];
      final cubit = createCubit(documentImporter: documentImporter);

      await cubit.scanDocuments();

      expect(cubit.state.documents, hasLength(1));
      expect(cubit.state.documents.single.fileName, 'scan.pdf');
      expect(cubit.state.isImporting, isFalse);
      expect(documentImporter.scanCalls, 1);
    });

    test('adds a photo', () async {
      final documentImporter = FakeDocumentImporter()
        ..photo = stagedDocument(
          fileName: 'photo.jpg',
          source: DocumentSource.photo,
        );
      final cubit = createCubit(documentImporter: documentImporter);

      await cubit.takePhoto();

      expect(cubit.state.documents, hasLength(1));
      expect(cubit.state.documents.single.fileName, 'photo.jpg');
      expect(cubit.state.isImporting, isFalse);
      expect(documentImporter.photoCalls, 1);
    });

    test('adds selected files', () async {
      final documentImporter = FakeDocumentImporter()
        ..pickedDocuments = [stagedDocument()];
      final cubit = createCubit(documentImporter: documentImporter);

      await cubit.pickDocuments();

      expect(cubit.state.documents, hasLength(1));
      expect(cubit.state.documents.single.fileName, 'receipt.pdf');
      expect(cubit.state.isImporting, isFalse);
      expect(documentImporter.pickFilesCalls, 1);
    });

    test('maps import failures to localization keys', () async {
      final documentImporter = FakeDocumentImporter()
        ..throwOnPickFiles = true
        ..importError = const DocumentImportException(
          DocumentImportFailure.fileTooLarge,
          fileName: 'large.pdf',
        );
      final cubit = createCubit(documentImporter: documentImporter);

      await cubit.pickDocuments();

      expect(
        cubit.state.documentError,
        'products.form.documents.error.fileTooLarge',
      );
      expect(cubit.state.documents, isEmpty);
      expect(cubit.state.isImporting, isFalse);
    });
  });

  group('document removal and opening', () {
    test('discards a staged document immediately', () async {
      final document = stagedDocument();
      final documentImporter = FakeDocumentImporter()
        ..pickedDocuments = [document];
      final cubit = createCubit(documentImporter: documentImporter);
      await cubit.pickDocuments();

      await cubit.removeDocument(document);

      expect(cubit.state.documents, isEmpty);
      expect(documentImporter.discardedDocuments, [document]);
    });

    test('marks a persisted document for deletion on save', () async {
      final document = persistedDocument();
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final documentRepository = FakeDocumentRepository([document]);
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        productId: 1,
      );
      await cubit.load();

      await cubit.removeDocument(document);

      expect(cubit.state.documents, isEmpty);
      expect(cubit.state.removedDocuments, [document]);
      expect(documentRepository.documents, hasLength(1));
    });

    test('opens a document with the system viewer', () async {
      final document = persistedDocument();
      final documentOpener = FakeDocumentOpener();
      final cubit = createCubit(documentOpener: documentOpener);

      await cubit.openDocument(document);

      expect(documentOpener.openedPaths, [document.filePath]);
    });

    test('maps open failures to localization keys', () async {
      final document = persistedDocument();
      final documentOpener = FakeDocumentOpener()
        ..openError = const DocumentOpenException(
          DocumentOpenFailure.noAppAvailable,
        );
      final cubit = createCubit(documentOpener: documentOpener);

      await cubit.openDocument(document);

      expect(cubit.state.documentError, 'products.form.documents.error.noApp');
    });
  });

  group('document persistence', () {
    test('persists staged documents when saving a new product', () async {
      final repository = FakeProductRepository();
      final documentRepository = FakeDocumentRepository();
      final documentImporter = FakeDocumentImporter()
        ..pickedDocuments = [stagedDocument()];
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        documentImporter: documentImporter,
      );
      await cubit.pickDocuments();

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saved);
      expect(documentRepository.documents, hasLength(1));
      expect(documentRepository.documents.single.id, isNotNull);
      expect(documentRepository.documents.single.productId, 1);
      expect(cubit.state.documents.single.isPersisted, isTrue);
    });

    test('deletes removed documents when saving', () async {
      final document = persistedDocument();
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final documentRepository = FakeDocumentRepository([document]);
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        productId: 1,
      );
      await cubit.load();
      await cubit.removeDocument(document);

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saved);
      expect(documentRepository.documents, isEmpty);
      expect(cubit.state.removedDocuments, isEmpty);
    });

    test('does not duplicate a product when save is retried', () async {
      final repository = FakeProductRepository();
      final documentRepository = FakeDocumentRepository()..throwOnAdd = true;
      final documentImporter = FakeDocumentImporter()
        ..pickedDocuments = [stagedDocument()];
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        documentImporter: documentImporter,
      );
      await cubit.pickDocuments();

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saveError);
      expect(repository.products, hasLength(1));
      expect(cubit.state.product?.id, 1);

      documentRepository.throwOnAdd = false;
      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saved);
      expect(repository.products, hasLength(1));
      expect(documentRepository.documents, hasLength(1));
    });

    test('discards staged documents when the form is closed', () async {
      final documentImporter = FakeDocumentImporter()
        ..pickedDocuments = [stagedDocument()];
      final cubit = createCubit(documentImporter: documentImporter);
      await cubit.pickDocuments();

      await cubit.close();

      expect(documentImporter.discardedDocuments, hasLength(1));
    });

    test('keeps persisted documents when the form is closed', () async {
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final documentRepository = FakeDocumentRepository([persistedDocument()]);
      final documentImporter = FakeDocumentImporter();
      final cubit = createCubit(
        repository: repository,
        documentRepository: documentRepository,
        documentImporter: documentImporter,
        productId: 1,
      );
      await cubit.load();

      await cubit.close();

      expect(documentImporter.discardedDocuments, isEmpty);
    });
  });
}

ProductFormCubit createCubit({
  FakeProductRepository? repository,
  FakeDocumentRepository? documentRepository,
  FakeDocumentImporter? documentImporter,
  FakeDocumentOpener? documentOpener,
  int? productId,
}) {
  return ProductFormCubit(
    repository: repository ?? FakeProductRepository(),
    documentRepository: documentRepository ?? FakeDocumentRepository(),
    documentImporter: documentImporter ?? FakeDocumentImporter(),
    documentOpener: documentOpener ?? FakeDocumentOpener(),
    productId: productId,
  );
}

WarrantyDocument stagedDocument({
  String fileName = 'receipt.pdf',
  String filePath = '/staged/receipt.pdf',
  DocumentSource source = DocumentSource.file,
}) {
  return WarrantyDocument(
    fileName: fileName,
    filePath: filePath,
    mimeType: 'application/pdf',
    sizeBytes: 10,
    source: source,
  );
}

WarrantyDocument persistedDocument({
  int id = 1,
  int productId = 1,
  String fileName = 'receipt.pdf',
}) {
  return WarrantyDocument(
    id: id,
    productId: productId,
    fileName: fileName,
    filePath: '/documents/$productId/$fileName',
    mimeType: 'application/pdf',
    sizeBytes: 10,
    source: DocumentSource.file,
    createdAt: DateTime(2026),
  );
}

extension on ProductFormData {
  ProductFormData copyWithText({
    String? name,
    String? priceText,
    String? currency,
  }) {
    return ProductFormData(
      name: name ?? this.name,
      brand: brand,
      model: model,
      store: store,
      purchaseDate: purchaseDate,
      priceText: priceText ?? this.priceText,
      currency: currency ?? this.currency,
      serialNumber: serialNumber,
      warrantyEndDate: warrantyEndDate,
      notes: notes,
    );
  }
}
