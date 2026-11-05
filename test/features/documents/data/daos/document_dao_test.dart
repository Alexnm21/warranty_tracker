import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/documents/data/daos/document_dao.dart';
import 'package:warranty_tracker/features/products/data/daos/product_dao.dart';

void main() {
  late AppDatabase db;
  late DocumentDao dao;
  late ProductDao productDao;
  late int productId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DocumentDao(db);
    productDao = ProductDao(db);
    productId = await _insertProduct(productDao, 'Laptop');
  });

  tearDown(() => db.close());

  test('returns the documents of a product ordered by creation date', () async {
    await dao.insertDocument(
      _document(
        productId: productId,
        fileName: 'second.pdf',
        createdAt: DateTime(2025, 1, 2),
      ),
    );
    await dao.insertDocument(
      _document(
        productId: productId,
        fileName: 'first.pdf',
        createdAt: DateTime(2025, 1, 1),
      ),
    );

    final rows = await dao.getByProduct(productId);

    expect(rows.map((row) => row.fileName), ['first.pdf', 'second.pdf']);
  });

  test('does not return documents from another product', () async {
    final otherProductId = await _insertProduct(productDao, 'Phone');
    await dao.insertDocument(
      _document(productId: otherProductId, fileName: 'phone.pdf'),
    );

    expect(await dao.getByProduct(productId), isEmpty);
  });

  test('deleteById removes only the requested document', () async {
    final firstId = await dao.insertDocument(
      _document(productId: productId, fileName: 'first.pdf'),
    );
    await dao.insertDocument(
      _document(productId: productId, fileName: 'second.pdf'),
    );

    await dao.deleteById(firstId);

    final rows = await dao.getByProduct(productId);
    expect(rows.map((row) => row.fileName), ['second.pdf']);
  });
}

Future<int> _insertProduct(ProductDao dao, String name) {
  final now = DateTime(2025, 1, 1);
  return dao.insertProduct(
    ProductsCompanion.insert(
      name: name,
      purchaseDate: now,
      warrantyEndDate: DateTime(2026, 1, 1),
      createdAt: now,
      updatedAt: now,
    ),
  );
}

ProductDocumentsCompanion _document({
  required int productId,
  required String fileName,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2025, 1, 1);

  return ProductDocumentsCompanion.insert(
    productId: productId,
    fileName: fileName,
    storagePath: 'warranty_documents/$productId/$fileName',
    mimeType: 'application/pdf',
    sizeBytes: 1024,
    source: 'file',
    createdAt: created,
  );
}
