import '../../domain/entities/product.dart';

/// Lifecycle of the product detail screen.
enum ProductDetailStatus { loading, loaded, notFound, error }

/// State for the product detail screen.
class ProductDetailState {
  const ProductDetailState({required this.status, this.product});

  final ProductDetailStatus status;
  final Product? product;

  ProductDetailState copyWith({ProductDetailStatus? status, Product? product}) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
    );
  }
}
