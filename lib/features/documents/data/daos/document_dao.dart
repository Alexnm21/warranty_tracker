import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/product_documents_table.dart';

part 'document_dao.g.dart';

@DriftAccessor(tables: [ProductDocuments])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.db);

  Future<List<ProductDocumentRow>> getByProduct(int productId) {
    return (select(productDocuments)
          ..where((table) => table.productId.equals(productId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.createdAt),
            (table) => OrderingTerm.asc(table.id),
          ]))
        .get();
  }

  Future<int> insertDocument(ProductDocumentsCompanion document) {
    return into(productDocuments).insert(document);
  }

  Future<int> deleteById(int id) {
    return (delete(
      productDocuments,
    )..where((table) => table.id.equals(id))).go();
  }
}
