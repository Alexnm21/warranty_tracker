import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../daos/product_dao.dart';
import '../mappers/product_mapper.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._dao);

  final ProductDao _dao;

  @override
  Future<List<Product>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(ProductMapper.toEntity).toList();
  }

  @override
  Future<Product?> getById(int id) async {
    final row = await _dao.getById(id);
    return row == null ? null : ProductMapper.toEntity(row);
  }

  @override
  Future<Product> create(Product product) async {
    final now = DateTime.now();
    final prepared = product.copyWith(
      createdAt: product.createdAt ?? now,
      updatedAt: product.updatedAt ?? now,
    );

    final id = await _dao.insertProduct(
      ProductMapper.toInsertCompanion(prepared),
    );
    return prepared.copyWith(id: id);
  }

  @override
  Future<Product> update(Product product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await _dao.updateProduct(ProductMapper.toRow(updated));
    return updated;
  }

  @override
  Future<void> delete(int id) => _dao.deleteById(id);

  @override
  Future<List<Product>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return getAll();
    }

    final rows = await _dao.search(trimmed);
    return rows.map(ProductMapper.toEntity).toList();
  }
}
