import '../../domain/entities/product.dart';

/// Lifecycle of the product form screen.
enum ProductFormStatus { loading, ready, saving, saved, loadError, saveError }

/// Fields that can carry a validation error.
enum ProductFormField {
  name,
  purchaseDate,
  warrantyStartDate,
  warrantyEndDate,
  price,
  currency,
}

/// State for the product create/edit form.
class ProductFormState {
  const ProductFormState({
    this.status = ProductFormStatus.ready,
    this.product,
    this.errors = const {},
  });

  final ProductFormStatus status;

  /// The product being edited, or the product last saved.
  final Product? product;

  /// Validation errors keyed by field; values are localization keys.
  final Map<ProductFormField, String> errors;

  ProductFormState copyWith({
    ProductFormStatus? status,
    Product? product,
    Map<ProductFormField, String>? errors,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      product: product ?? this.product,
      errors: errors ?? this.errors,
    );
  }
}
