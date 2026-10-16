import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/domain/repositories/product_repository.dart';

/// In-memory [ProductRepository] for tests.
///
/// Set any `throwOn*` flag to make that operation fail, so cubits can be tested
/// against both success and error paths without a real database.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository([List<Product>? initial]) : _products = [...?initial] {
    for (final product in _products) {
      if (product.id != null && product.id! >= _nextId) {
        _nextId = product.id! + 1;
      }
    }
  }

  final List<Product> _products;
  int _nextId = 1;

  bool throwOnGetAll = false;
  bool throwOnGetById = false;
  bool throwOnCreate = false;
  bool throwOnUpdate = false;
  bool throwOnDelete = false;

  List<Product> get products => List.unmodifiable(_products);

  @override
  Future<List<Product>> getAll() async {
    _maybeThrow(throwOnGetAll);
    return List.of(_products);
  }

  @override
  Future<Product?> getById(int id) async {
    _maybeThrow(throwOnGetById);
    for (final product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  @override
  Future<Product> create(Product product) async {
    _maybeThrow(throwOnCreate);
    final created = product.copyWith(id: _nextId++);
    _products.add(created);
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    _maybeThrow(throwOnUpdate);
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    }
    return product;
  }

  @override
  Future<void> delete(int id) async {
    _maybeThrow(throwOnDelete);
    _products.removeWhere((product) => product.id == id);
  }

  @override
  Future<List<Product>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return List.of(_products);
    }

    return _products.where((product) {
      final fields = [
        product.name,
        product.brand,
        product.model,
        product.store,
        product.serialNumber,
      ];
      return fields.whereType<String>().any(
        (value) => value.toLowerCase().contains(needle),
      );
    }).toList();
  }

  void _maybeThrow(bool shouldThrow) {
    if (shouldThrow) {
      throw Exception('FakeProductRepository failure');
    }
  }
}
