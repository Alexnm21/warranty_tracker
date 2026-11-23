import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/product_repository.dart';
import 'product_list_state.dart';

/// Drives the product list screen: loading, searching and deleting products.
///
/// Starts in the [ProductListStatus.loading] state and relies on the repository
/// for all data access; it never touches the database directly.
class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit(this._repository)
    : super(const ProductListState(status: ProductListStatus.loading));

  final ProductRepository _repository;

  /// Loads every product and emits the result.
  ///
  /// Falls back to [ProductListStatus.error] if the repository throws.
  Future<void> load() async {
    emit(state.copyWith(status: ProductListStatus.loading));

    try {
      final products = await _repository.getAll();
      emit(
        state.copyWith(status: ProductListStatus.loaded, products: products),
      );
    } catch (_) {
      emit(state.copyWith(status: ProductListStatus.error));
    }
  }

  /// Filters products by [query] and stores it in the state.
  ///
  /// An empty query returns all products. Emits [ProductListStatus.error] on
  /// failure.
  Future<void> search(String query) async {
    emit(state.copyWith(query: query));

    try {
      final products = await _repository.search(query);
      emit(
        state.copyWith(status: ProductListStatus.loaded, products: products),
      );
    } catch (_) {
      emit(state.copyWith(status: ProductListStatus.error));
    }
  }

  /// Deletes the product with [id] and refreshes the list.
  ///
  /// Returns `true` on success, or `false` if the operation failed so the UI
  /// can show an error message without corrupting the current state.
  Future<bool> delete(int id) async {
    try {
      await _repository.delete(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
