import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAll();
  Future<Product?> getById(int id);
  Future<Product> create(Product product);
  Future<Product> update(Product product);
  Future<void> delete(int id);
  Future<List<Product>> search(String query);
}
