import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/price_format.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'product_form_state.dart';

/// Raw values entered in the form, before validation or mapping to a [Product].
class ProductFormData {
  const ProductFormData({
    required this.name,
    this.brand,
    this.model,
    this.store,
    this.purchaseDate,
    this.priceText = '',
    this.currency,
    this.serialNumber,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.notes,
  });

  final String name;
  final String? brand;
  final String? model;
  final String? store;
  final DateTime? purchaseDate;
  final String priceText;
  final String? currency;
  final String? serialNumber;
  final DateTime? warrantyStartDate;
  final DateTime? warrantyEndDate;
  final String? notes;
}

/// Drives the product create/edit form: loads the product when editing and
/// validates + persists it on save.
///
/// Created with the target `productId` (null to create). Business validation
/// lives here so it stays out of the widgets and is unit-testable.
class ProductFormCubit extends Cubit<ProductFormState> {
  ProductFormCubit(this._repository, {int? productId})
    : _productId = productId,
      super(
        ProductFormState(
          status: productId == null
              ? ProductFormStatus.ready
              : ProductFormStatus.loading,
        ),
      );

  final ProductRepository _repository;
  final int? _productId;

  /// Loads the product being edited. No-op when creating a new product.
  Future<void> load() async {
    if (_productId == null) {
      return;
    }

    try {
      final product = await _repository.getById(_productId);
      if (product == null) {
        emit(const ProductFormState(status: ProductFormStatus.loadError));
      } else {
        emit(
          ProductFormState(status: ProductFormStatus.ready, product: product),
        );
      }
    } catch (_) {
      emit(const ProductFormState(status: ProductFormStatus.loadError));
    }
  }

  /// Validates [data] and persists it.
  ///
  /// Emits the validation errors without touching the repository when invalid,
  /// then [ProductFormStatus.saved] or [ProductFormStatus.saveError].
  Future<void> save(ProductFormData data) async {
    final errors = _validate(data);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return;
    }

    emit(state.copyWith(status: ProductFormStatus.saving, errors: const {}));

    try {
      final product = _toProduct(data);
      final saved = _productId == null
          ? await _repository.create(product)
          : await _repository.update(product);
      emit(state.copyWith(status: ProductFormStatus.saved, product: saved));
    } catch (_) {
      emit(state.copyWith(status: ProductFormStatus.saveError));
    }
  }

  Map<ProductFormField, String> _validate(ProductFormData data) {
    final errors = <ProductFormField, String>{};

    if (data.name.trim().isEmpty) {
      errors[ProductFormField.name] = 'products.form.error.nameRequired';
    }
    if (data.purchaseDate == null) {
      errors[ProductFormField.purchaseDate] =
          'products.form.error.purchaseDateRequired';
    }
    if (data.warrantyStartDate == null) {
      errors[ProductFormField.warrantyStartDate] =
          'products.form.error.warrantyStartRequired';
    }
    if (data.warrantyEndDate == null) {
      errors[ProductFormField.warrantyEndDate] =
          'products.form.error.warrantyEndRequired';
    } else if (data.warrantyStartDate != null &&
        data.warrantyEndDate!.isBefore(data.warrantyStartDate!)) {
      errors[ProductFormField.warrantyEndDate] =
          'products.form.error.warrantyEndBeforeStart';
    }

    final priceText = data.priceText.trim();
    int? price;
    if (priceText.isNotEmpty) {
      price = parsePrice(priceText);
      if (price == null) {
        errors[ProductFormField.price] = 'products.form.error.priceInvalid';
      }
    }

    final currency = data.currency?.trim() ?? '';
    if (price != null && currency.isEmpty) {
      errors[ProductFormField.currency] =
          'products.form.error.currencyRequired';
    }

    return errors;
  }

  Product _toProduct(ProductFormData data) {
    final priceText = data.priceText.trim();
    final price = priceText.isEmpty ? null : parsePrice(priceText);
    final currency = _nullIfEmpty(data.currency);
    final existing = state.product;

    return Product(
      id: _productId,
      name: data.name.trim(),
      brand: _nullIfEmpty(data.brand),
      model: _nullIfEmpty(data.model),
      store: _nullIfEmpty(data.store),
      purchaseDate: data.purchaseDate,
      price: price,
      currency: price == null ? null : currency,
      serialNumber: _nullIfEmpty(data.serialNumber),
      warrantyStartDate: data.warrantyStartDate,
      warrantyEndDate: data.warrantyEndDate,
      notes: _nullIfEmpty(data.notes),
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );
  }

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
