import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_exception.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_detail_state.dart';

import '../fakes/fake_document_opener.dart';
import '../fakes/fake_document_repository.dart';
import '../fakes/fake_product_repository.dart';

void main() {
  test('starts in the loading state', () {
    final cubit = _cubit();

    expect(cubit.state.status, ProductDetailStatus.loading);
    expect(cubit.state.documentsStatus, ProductDetailDocumentsStatus.loading);
  });

  test('load emits the product and its documents', () async {
    final product = const Product(id: 1, name: 'Laptop');
    final document = _document();

    final cubit = _cubit(
      products: [product],
      documentRepository: FakeDocumentRepository([document]),
    );

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.loaded);
    expect(cubit.state.product?.name, 'Laptop');
    expect(cubit.state.documents, [document]);
    expect(cubit.state.documentsStatus, ProductDetailDocumentsStatus.loaded);
  });

  test('load emits notFound when the product does not exist', () async {
    final cubit = _cubit(productId: 99);

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.notFound);
    expect(cubit.state.product, isNull);
  });

  test('load emits error when the product repository fails', () async {
    final repository = FakeProductRepository()..throwOnGetById = true;
    final cubit = _cubit(productRepository: repository);

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.error);
  });

  test('load keeps the product when documents fail', () async {
    final documentRepository = FakeDocumentRepository([_document()])
      ..throwOnGetByProduct = true;
    final cubit = _cubit(
      products: [const Product(id: 1, name: 'Laptop')],
      documentRepository: documentRepository,
    );

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.loaded);
    expect(cubit.state.product?.name, 'Laptop');
    expect(cubit.state.documents, isEmpty);
    expect(cubit.state.documentsStatus, ProductDetailDocumentsStatus.error);
  });

  test('loadDocuments retries after a load error', () async {
    final document = _document();
    final documentRepository = FakeDocumentRepository([document])
      ..throwOnGetByProduct = true;
    final cubit = _cubit(
      products: [const Product(id: 1, name: 'Laptop')],
      documentRepository: documentRepository,
    );

    await cubit.load();
    expect(cubit.state.documentsStatus, ProductDetailDocumentsStatus.error);

    documentRepository.throwOnGetByProduct = false;
    await cubit.loadDocuments();

    expect(cubit.state.documents, [document]);
    expect(cubit.state.documentsStatus, ProductDetailDocumentsStatus.loaded);
  });

  test('openDocument opens the file with the system viewer', () async {
    final document = _document();
    final documentOpener = FakeDocumentOpener();
    final cubit = _cubit(documentOpener: documentOpener);

    await cubit.openDocument(document);

    expect(documentOpener.openedPaths, [document.filePath]);
    expect(cubit.state.documentError, isNull);
  });

  test('openDocument maps an open failure to a localization key', () async {
    final documentOpener = FakeDocumentOpener()
      ..openError = const DocumentOpenException(
        DocumentOpenFailure.noAppAvailable,
      );
    final cubit = _cubit(documentOpener: documentOpener);

    await cubit.openDocument(_document());

    expect(cubit.state.documentError, 'products.form.documents.error.noApp');
  });

  test('openDocument clears a previous error on success', () async {
    final documentOpener = FakeDocumentOpener()
      ..openError = const DocumentOpenException(DocumentOpenFailure.failed);
    final cubit = _cubit(documentOpener: documentOpener);

    await cubit.openDocument(_document());
    expect(cubit.state.documentError, 'products.form.documents.error.open');

    documentOpener.openError = null;
    await cubit.openDocument(_document());

    expect(cubit.state.documentError, isNull);
  });

  test('deleteDocument removes the document from the state', () async {
    final document = _document();
    final documentRepository = FakeDocumentRepository([document]);
    final cubit = _cubit(
      products: [const Product(id: 1, name: 'Laptop')],
      documentRepository: documentRepository,
    );
    await cubit.load();

    await cubit.deleteDocument(document);

    expect(cubit.state.documents, isEmpty);
    expect(cubit.state.documentError, isNull);
    expect(documentRepository.documents, isEmpty);
  });

  test('deleteDocument maps a failure to a localization key', () async {
    final document = _document();
    final documentRepository = FakeDocumentRepository([document])
      ..throwOnDelete = true;
    final cubit = _cubit(
      products: [const Product(id: 1, name: 'Laptop')],
      documentRepository: documentRepository,
    );
    await cubit.load();

    await cubit.deleteDocument(document);

    expect(cubit.state.documents, [document]);
    expect(cubit.state.documentError, 'documents.error.delete');
  });

  test('deleteDocument ignores documents that were never persisted', () async {
    final documentRepository = FakeDocumentRepository()..throwOnDelete = true;
    final cubit = _cubit(documentRepository: documentRepository);

    await cubit.deleteDocument(
      const WarrantyDocument(
        fileName: 'staged.pdf',
        filePath: '/staging/staged.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 5,
        source: DocumentSource.file,
      ),
    );

    expect(cubit.state.documentError, isNull);
  });

  test('delete returns true and removes the product', () async {
    final repository = FakeProductRepository([
      const Product(id: 1, name: 'Laptop'),
    ]);
    final cubit = _cubit(productRepository: repository);

    final success = await cubit.delete();

    expect(success, isTrue);
    expect(repository.products, isEmpty);
  });

  test('delete returns false when the repository fails', () async {
    final repository = FakeProductRepository([
      const Product(id: 1, name: 'Laptop'),
    ])..throwOnDelete = true;
    final cubit = _cubit(productRepository: repository);

    final success = await cubit.delete();

    expect(success, isFalse);
    expect(repository.products.length, 1);
  });
}

ProductDetailCubit _cubit({
  List<Product> products = const [],
  FakeProductRepository? productRepository,
  FakeDocumentRepository? documentRepository,
  FakeDocumentOpener? documentOpener,
  int productId = 1,
}) {
  return ProductDetailCubit(
    repository: productRepository ?? FakeProductRepository(products),
    documentRepository: documentRepository ?? FakeDocumentRepository(),
    documentOpener: documentOpener ?? FakeDocumentOpener(),
    productId: productId,
  );
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
