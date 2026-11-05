import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../documents/data/services/document_opener.dart';
import '../../../documents/domain/entities/document_exception.dart';
import '../../../documents/domain/entities/warranty_document.dart';
import '../../../documents/domain/repositories/document_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../utils/document_error_keys.dart';
import 'product_detail_state.dart';

/// Loads a single product and its documents for the detail screen.
///
/// Created with the target `productId` supplied by the route. Relies on the
/// repositories for all data access; it never touches the database directly.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({
    required ProductRepository repository,
    required DocumentRepository documentRepository,
    required DocumentOpener documentOpener,
    required int productId,
  }) : _repository = repository,
       _documentRepository = documentRepository,
       _documentOpener = documentOpener,
       _productId = productId,
       super(const ProductDetailState(status: ProductDetailStatus.loading));

  final ProductRepository _repository;
  final DocumentRepository _documentRepository;
  final DocumentOpener _documentOpener;
  final int _productId;

  /// Loads the product and its documents.
  ///
  /// Emits [ProductDetailStatus.notFound] when the product does not exist and
  /// [ProductDetailStatus.error] when the product repository throws. Document
  /// load failures leave the product visible and set
  /// [ProductDetailDocumentsStatus.error] for the documents section.
  Future<void> load() async {
    emit(state.copyWith(status: ProductDetailStatus.loading));

    try {
      final product = await _repository.getById(_productId);
      if (isClosed) {
        return;
      }

      if (product == null) {
        emit(const ProductDetailState(status: ProductDetailStatus.notFound));
        return;
      }

      emit(
        state.copyWith(
          status: ProductDetailStatus.loaded,
          product: product,
          documents: const [],
          documentsStatus: ProductDetailDocumentsStatus.loading,
          clearDocumentError: true,
        ),
      );

      await loadDocuments();
    } on Exception {
      if (!isClosed) {
        emit(const ProductDetailState(status: ProductDetailStatus.error));
      }
    }
  }

  /// Loads or reloads the product's documents.
  Future<void> loadDocuments() async {
    if (isClosed || state.status != ProductDetailStatus.loaded) {
      return;
    }

    emit(
      state.copyWith(
        documentsStatus: ProductDetailDocumentsStatus.loading,
        clearDocumentError: true,
      ),
    );

    try {
      final documents = await _documentRepository.getByProduct(_productId);
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          documents: documents,
          documentsStatus: ProductDetailDocumentsStatus.loaded,
        ),
      );
    } on Exception {
      if (!isClosed) {
        emit(
          state.copyWith(documentsStatus: ProductDetailDocumentsStatus.error),
        );
      }
    }
  }

  /// Opens a document with the system viewer.
  Future<void> openDocument(WarrantyDocument document) async {
    if (isClosed) {
      return;
    }

    emit(state.copyWith(clearDocumentError: true));

    try {
      await _documentOpener.open(document.filePath);
    } on DocumentOpenException catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(documentError: documentOpenErrorKey(error.failure)));
    } on Exception {
      if (!isClosed) {
        emit(
          state.copyWith(documentError: 'products.form.documents.error.open'),
        );
      }
    }
  }

  /// Deletes the product.
  ///
  /// Returns `true` on success, or `false` if the operation failed so the UI
  /// can show an error message before navigating away.
  Future<bool> delete() async {
    try {
      await _repository.delete(_productId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
