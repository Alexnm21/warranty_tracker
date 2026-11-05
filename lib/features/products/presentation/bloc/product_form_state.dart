import '../../../documents/domain/entities/warranty_document.dart';
import '../../domain/entities/product.dart';

/// Lifecycle of the product form screen.
enum ProductFormStatus { loading, ready, saving, saved, loadError, saveError }

/// Fields that can carry a validation error.
enum ProductFormField { name, purchaseDate, warrantyEndDate, price, currency }

/// State for the product create/edit form.
class ProductFormState {
  const ProductFormState({
    this.status = ProductFormStatus.ready,
    this.product,
    this.errors = const {},
    this.documents = const [],
    this.removedDocuments = const [],
    this.documentError,
    this.isImporting = false,
  });

  final ProductFormStatus status;

  /// The product being edited, or the product last saved.
  final Product? product;

  /// Validation errors keyed by field; values are localization keys.
  final Map<ProductFormField, String> errors;

  /// Persisted and staged warranty documents shown in the form.
  final List<WarrantyDocument> documents;

  /// Persisted documents marked for deletion when the product is saved.
  final List<WarrantyDocument> removedDocuments;

  /// Document error as a localization key.
  final String? documentError;

  /// Whether a document is currently being imported.
  final bool isImporting;

  ProductFormState copyWith({
    ProductFormStatus? status,
    Product? product,
    Map<ProductFormField, String>? errors,
    List<WarrantyDocument>? documents,
    List<WarrantyDocument>? removedDocuments,
    String? documentError,
    bool clearDocumentError = false,
    bool? isImporting,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      product: product ?? this.product,
      errors: errors ?? this.errors,
      documents: documents ?? this.documents,
      removedDocuments: removedDocuments ?? this.removedDocuments,
      documentError: clearDocumentError
          ? null
          : (documentError ?? this.documentError),
      isImporting: isImporting ?? this.isImporting,
    );
  }
}
