import '../../../documents/domain/entities/warranty_document.dart';
import '../../domain/entities/product.dart';

/// Lifecycle of the product detail screen.
enum ProductDetailStatus { loading, loaded, notFound, error }

/// Lifecycle of the documents section in the product detail screen.
enum ProductDetailDocumentsStatus { loading, loaded, error }

/// State for the product detail screen.
class ProductDetailState {
  const ProductDetailState({
    required this.status,
    this.product,
    this.documents = const [],
    this.documentsStatus = ProductDetailDocumentsStatus.loading,
    this.documentError,
  });

  final ProductDetailStatus status;
  final Product? product;

  /// Persisted documents attached to the product.
  final List<WarrantyDocument> documents;

  /// Whether [documents] are loading, loaded or failed to load.
  final ProductDetailDocumentsStatus documentsStatus;

  /// Document open error as a localization key.
  final String? documentError;

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    List<WarrantyDocument>? documents,
    ProductDetailDocumentsStatus? documentsStatus,
    String? documentError,
    bool clearDocumentError = false,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      documents: documents ?? this.documents,
      documentsStatus: documentsStatus ?? this.documentsStatus,
      documentError: clearDocumentError
          ? null
          : (documentError ?? this.documentError),
    );
  }
}
