import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/documents/data/daos/document_dao.dart';
import 'package:warranty_tracker/features/documents/data/repositories/document_repository_impl.dart';
import 'package:warranty_tracker/features/documents/data/services/document_file_storage.dart';
import 'package:warranty_tracker/features/documents/domain/entities/document_source.dart';
import 'package:warranty_tracker/features/documents/domain/entities/warranty_document.dart';
import 'package:warranty_tracker/features/products/data/daos/product_dao.dart';

void main() {
  late AppDatabase db;
  late DocumentDao documentDao;
  late ProductDao productDao;
  late DocumentFileStorage storage;
  late DocumentRepositoryImpl repository;
  late Directory tempDirectory;
  late int productId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    documentDao = DocumentDao(db);
    productDao = ProductDao(db);
    tempDirectory = await Directory.systemTemp.createTemp(
      'document_repository',
    );
    storage = DocumentFileStorage(baseDirectory: tempDirectory);
    repository = DocumentRepositoryImpl(documentDao, storage);
    productId = await _insertProduct(productDao);
  });

  tearDown(() async {
    await db.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('add persists the file and its metadata', () async {
    final staged = await _stageFile(
      storage,
      tempDirectory,
      'receipt.pdf',
      'content',
    );

    final saved = await repository.add(
      productId,
      _document(staged.path, fileName: 'receipt.pdf'),
    );

    expect(saved.id, isNotNull);
    expect(saved.productId, productId);
    expect(saved.createdAt, isNotNull);
    expect(await File(saved.filePath).exists(), isTrue);

    final rows = await documentDao.getByProduct(productId);
    expect(rows, hasLength(1));
    expect(
      rows.single.storagePath,
      startsWith('warranty_documents/$productId/'),
    );
    expect(rows.single.fileName, 'receipt.pdf');
    expect(await File(staged.path).exists(), isFalse);
  });

  test('getByProduct resolves stored paths to absolute paths', () async {
    final staged = await _stageFile(
      storage,
      tempDirectory,
      'receipt.pdf',
      'content',
    );
    final saved = await repository.add(
      productId,
      _document(staged.path, fileName: 'receipt.pdf'),
    );

    final documents = await repository.getByProduct(productId);

    expect(documents, hasLength(1));
    expect(documents.single.filePath, saved.filePath);
    expect(await File(documents.single.filePath).readAsString(), 'content');
  });

  test('add fails when the staged file is missing', () async {
    final document = _document(
      '${tempDirectory.path}/missing/receipt.pdf',
      fileName: 'receipt.pdf',
    );

    expect(
      () => repository.add(productId, document),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('delete removes the metadata and the stored file', () async {
    final staged = await _stageFile(
      storage,
      tempDirectory,
      'receipt.pdf',
      'content',
    );
    final saved = await repository.add(
      productId,
      _document(staged.path, fileName: 'receipt.pdf'),
    );

    await repository.delete(saved);

    expect(await documentDao.getByProduct(productId), isEmpty);
    expect(await File(saved.filePath).exists(), isFalse);
  });

  test('delete rejects documents that were never persisted', () async {
    final staged = await _stageFile(
      storage,
      tempDirectory,
      'receipt.pdf',
      'content',
    );

    expect(
      () => repository.delete(_document(staged.path, fileName: 'receipt.pdf')),
      throwsArgumentError,
    );
  });

  test('deleteStoredFilesForProduct removes the product folder', () async {
    final staged = await _stageFile(
      storage,
      tempDirectory,
      'receipt.pdf',
      'content',
    );
    await repository.add(
      productId,
      _document(staged.path, fileName: 'receipt.pdf'),
    );
    final productDirectory = Directory(
      '${tempDirectory.path}/warranty_documents/$productId',
    );
    expect(await productDirectory.exists(), isTrue);

    await repository.deleteStoredFilesForProduct(productId);

    expect(await productDirectory.exists(), isFalse);
  });

  test('deleting the product cascades to its document metadata', () async {
    final staged = await _stageFile(
      storage,
      tempDirectory,
      'receipt.pdf',
      'content',
    );
    await repository.add(
      productId,
      _document(staged.path, fileName: 'receipt.pdf'),
    );

    await productDao.deleteById(productId);

    expect(await documentDao.getByProduct(productId), isEmpty);
  });
}

Future<File> _stageFile(
  DocumentFileStorage storage,
  Directory directory,
  String name,
  String content,
) async {
  final source = File('${directory.path}/$name');
  await source.writeAsString(content);
  return storage.stage(source, fileName: name);
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

WarrantyDocument _document(String filePath, {required String fileName}) {
  return WarrantyDocument(
    fileName: fileName,
    filePath: filePath,
    mimeType: 'application/pdf',
    sizeBytes: 7,
    source: DocumentSource.file,
  );
}
