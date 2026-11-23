import '../../domain/entities/product.dart';

enum ProductListStatus { loading, loaded, error }

class ProductListState {
  const ProductListState({
    required this.status,
    this.products = const [],
    this.query = '',
  });

  final ProductListStatus status;
  final List<Product> products;
  final String query;

  ProductListState copyWith({
    ProductListStatus? status,
    List<Product>? products,
    String? query,
  }) {
    return ProductListState(
      status: status ?? this.status,
      products: products ?? this.products,
      query: query ?? this.query,
    );
  }
}
