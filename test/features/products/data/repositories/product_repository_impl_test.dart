import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/documents/data/daos/document_dao.dart';
import 'package:warranty_tracker/features/documents/data/repositories/document_repository_impl.dart';
import 'package:warranty_tracker/features/documents/data/services/document_file_storage.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/documents/domain/repositories/document_repository.dart';
import 'package:warranty_tracker/features/products/data/daos/product_dao.dart';
import 'package:warranty_tracker/features/products/data/repositories/product_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ProductDao productDao;
  late DocumentDao documentDao;
  late DocumentFileStorage storage;
  late ProductRepositoryImpl repository;
  late Directory tempDirectory;
  late int productId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    productDao = ProductDao(db);
    documentDao = DocumentDao(db);
    tempDirectory = await Directory.systemTemp.createTemp('product_repository');
    storage = DocumentFileStorage(baseDirectory: tempDirectory);
    repository = ProductRepositoryImpl(
      productDao,
      DocumentRepositoryImpl(documentDao, storage),
    );
    productId = await _insertProduct(productDao);
  });

  tearDown(() async {
    await db.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('delete removes the product and cascades to its documents', () async {
    await _addDocument(storage, tempDirectory, documentDao, productId);

    await repository.delete(productId);

    expect(await productDao.getById(productId), isNull);
    expect(await documentDao.getByProduct(productId), isEmpty);
  });

  test('delete removes the stored document files', () async {
    await _addDocument(storage, tempDirectory, documentDao, productId);
    final productDirectory = Directory(
      '${tempDirectory.path}/warranty_documents/$productId',
    );
    expect(await productDirectory.exists(), isTrue);

    await repository.delete(productId);

    expect(await productDirectory.exists(), isFalse);
  });

  test('delete completes when the document cleanup fails', () async {
    final repository = ProductRepositoryImpl(
      productDao,
      _ThrowingDocumentRepository(),
    );

    await expectLater(repository.delete(productId), completes);

    expect(await productDao.getById(productId), isNull);
  });
}

Future<int> _insertProduct(ProductDao dao) {
  final now = DateTime(2025, 1, 1);
  return dao.insertProduct(
    ProductsCompanion.insert(
      name: 'Laptop',
      purchaseDate: now,
      warrantyEndDate: DateTime(2026, 1, 1),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<void> _addDocument(
  DocumentFileStorage storage,
  Directory directory,
  DocumentDao documentDao,
  int productId,
) async {
  final source = File('${directory.path}/receipt.pdf');
  await source.writeAsString('content');
  final staged = await storage.stage(source, fileName: 'receipt.pdf');

  await DocumentRepositoryImpl(documentDao, storage).add(
    productId,
    WarrantyDocument(
      fileName: 'receipt.pdf',
      filePath: staged.path,
      mimeType: 'application/pdf',
      sizeBytes: 7,
      source: DocumentSource.file,
    ),
  );
}

/// Document repository whose file cleanup always fails.
class _ThrowingDocumentRepository implements DocumentRepository {
  @override
  Future<List<WarrantyDocument>> getByProduct(int productId) async {
    throw UnimplementedError();
  }

  @override
  Future<WarrantyDocument> add(int productId, WarrantyDocument document) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(WarrantyDocument document) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteStoredFilesForProduct(int productId) async {
    throw const FileSystemException('cleanup failed');
  }
}
