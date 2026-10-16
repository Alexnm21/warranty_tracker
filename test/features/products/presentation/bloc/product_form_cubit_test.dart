import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_form_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_form_state.dart';

import '../fakes/fake_product_repository.dart';

void main() {
  final purchaseDate = DateTime(2026, 1, 5);
  final start = DateTime(2026, 1, 5);
  final end = DateTime(2027, 1, 5);

  ProductFormData validData() => ProductFormData(
    name: 'Laptop',
    purchaseDate: purchaseDate,
    warrantyStartDate: start,
    warrantyEndDate: end,
  );

  group('create mode', () {
    test('starts ready without loading', () async {
      final cubit = ProductFormCubit(FakeProductRepository());

      expect(cubit.state.status, ProductFormStatus.ready);

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.ready);
    });

    test('saves a valid product', () async {
      final repository = FakeProductRepository();
      final cubit = ProductFormCubit(repository);

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saved);
      expect(cubit.state.product?.id, isNotNull);
      expect(repository.products.single.name, 'Laptop');
    });

    test('converts the price to minor units and trims the currency', () async {
      final repository = FakeProductRepository();
      final cubit = ProductFormCubit(repository);

      await cubit.save(
        validData().copyWithText(priceText: '899.99', currency: ' EUR '),
      );

      expect(repository.products.single.price, 89999);
      expect(repository.products.single.currency, 'EUR');
    });

    test('stores no price or currency when the price is empty', () async {
      final repository = FakeProductRepository();
      final cubit = ProductFormCubit(repository);

      await cubit.save(validData().copyWithText(currency: 'EUR'));

      expect(repository.products.single.price, isNull);
      expect(repository.products.single.currency, isNull);
    });

    test('rejects an empty name', () async {
      final repository = FakeProductRepository();
      final cubit = ProductFormCubit(repository);

      await cubit.save(validData().copyWithText(name: '   '));

      expect(cubit.state.errors[ProductFormField.name], isNotNull);
      expect(cubit.state.status, ProductFormStatus.ready);
      expect(repository.products, isEmpty);
    });

    test('requires the purchase and warranty dates', () async {
      final cubit = ProductFormCubit(FakeProductRepository());

      await cubit.save(const ProductFormData(name: 'Laptop'));

      expect(cubit.state.errors[ProductFormField.purchaseDate], isNotNull);
      expect(cubit.state.errors[ProductFormField.warrantyStartDate], isNotNull);
      expect(cubit.state.errors[ProductFormField.warrantyEndDate], isNotNull);
    });

    test('rejects a warranty end before its start', () async {
      final cubit = ProductFormCubit(FakeProductRepository());

      await cubit.save(
        ProductFormData(
          name: 'Laptop',
          purchaseDate: purchaseDate,
          warrantyStartDate: DateTime(2027, 1, 5),
          warrantyEndDate: DateTime(2026, 1, 5),
        ),
      );

      expect(
        cubit.state.errors[ProductFormField.warrantyEndDate],
        'products.form.error.warrantyEndBeforeStart',
      );
    });

    test('rejects an invalid price', () async {
      final cubit = ProductFormCubit(FakeProductRepository());

      await cubit.save(validData().copyWithText(priceText: 'abc'));

      expect(cubit.state.errors[ProductFormField.price], isNotNull);
    });

    test('rejects a negative price', () async {
      final cubit = ProductFormCubit(FakeProductRepository());

      await cubit.save(validData().copyWithText(priceText: '-5'));

      expect(cubit.state.errors[ProductFormField.price], isNotNull);
    });

    test('requires a currency when a price is set', () async {
      final cubit = ProductFormCubit(FakeProductRepository());

      await cubit.save(validData().copyWithText(priceText: '10'));

      expect(cubit.state.errors[ProductFormField.currency], isNotNull);
    });

    test('emits saveError when the repository fails', () async {
      final repository = FakeProductRepository()..throwOnCreate = true;
      final cubit = ProductFormCubit(repository);

      await cubit.save(validData());

      expect(cubit.state.status, ProductFormStatus.saveError);
    });
  });

  group('edit mode', () {
    test('loads the product being edited', () async {
      final repository = FakeProductRepository([
        Product(id: 1, name: 'Laptop'),
      ]);
      final cubit = ProductFormCubit(repository, productId: 1);

      expect(cubit.state.status, ProductFormStatus.loading);

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.ready);
      expect(cubit.state.product?.name, 'Laptop');
    });

    test('emits loadError when the product is missing', () async {
      final cubit = ProductFormCubit(FakeProductRepository(), productId: 99);

      await cubit.load();

      expect(cubit.state.status, ProductFormStatus.loadError);
    });

    test('updates the product and preserves id and createdAt', () async {
      final createdAt = DateTime(2025, 1, 1);
      final repository = FakeProductRepository([
        Product(
          id: 1,
          name: 'Laptop',
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      ]);
      final cubit = ProductFormCubit(repository, productId: 1);
      await cubit.load();

      await cubit.save(validData().copyWithText(name: 'Renamed'));

      final saved = repository.products.single;
      expect(saved.id, 1);
      expect(saved.name, 'Renamed');
      expect(saved.createdAt, createdAt);
    });
  });
}

extension on ProductFormData {
  ProductFormData copyWithText({
    String? name,
    String? priceText,
    String? currency,
  }) {
    return ProductFormData(
      name: name ?? this.name,
      brand: brand,
      model: model,
      store: store,
      purchaseDate: purchaseDate,
      priceText: priceText ?? this.priceText,
      currency: currency ?? this.currency,
      serialNumber: serialNumber,
      warrantyStartDate: warrantyStartDate,
      warrantyEndDate: warrantyEndDate,
      notes: notes,
    );
  }
}
