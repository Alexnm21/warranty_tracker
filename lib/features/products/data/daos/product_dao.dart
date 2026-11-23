import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/products_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<ProductRow>> getAll() {
    return (select(
      products,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
  }

  Future<ProductRow?> getById(int id) {
    return (select(
      products,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future<bool> updateProduct(ProductRow product) {
    return update(products).replace(product);
  }

  Future<int> deleteById(int id) {
    return (delete(products)..where((table) => table.id.equals(id))).go();
  }

  Future<List<ProductRow>> search(String query) {
    final pattern = '%${_escapeLike(query.toLowerCase())}%';

    return (select(products)
          ..where(
            (table) =>
                [
                      table.name,
                      table.brand,
                      table.model,
                      table.store,
                      table.serialNumber,
                    ]
                    .map((column) => _matches(column, pattern))
                    .reduce((a, b) => a | b),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
  }

  Expression<bool> _matches(Expression<String> column, String pattern) {
    return column.lower().like(pattern, escapeChar: r'\');
  }

  String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
