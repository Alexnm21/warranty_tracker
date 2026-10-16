import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/product_repository.dart';
import 'product_detail_state.dart';

/// Loads a single product and exposes delete for the detail screen.
///
/// Created with the target [productId] supplied by the route. Relies on the
/// repository for all data access; it never touches the database directly.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit(this._repository, int productId)
    : _productId = productId,
      super(const ProductDetailState(status: ProductDetailStatus.loading));

  final ProductRepository _repository;
  final int _productId;

  /// Loads the product, emitting [ProductDetailStatus.notFound] when it does
  /// not exist and [ProductDetailStatus.error] when the repository throws.
  Future<void> load() async {
    emit(const ProductDetailState(status: ProductDetailStatus.loading));

    try {
      final product = await _repository.getById(_productId);
      if (product == null) {
        emit(const ProductDetailState(status: ProductDetailStatus.notFound));
      } else {
        emit(
          ProductDetailState(
            status: ProductDetailStatus.loaded,
            product: product,
          ),
        );
      }
    } catch (_) {
      emit(const ProductDetailState(status: ProductDetailStatus.error));
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
