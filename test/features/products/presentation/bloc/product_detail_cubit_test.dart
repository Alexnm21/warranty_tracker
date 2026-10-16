import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_detail_state.dart';

import '../fakes/fake_product_repository.dart';

void main() {
  test('starts in the loading state', () {
    final cubit = ProductDetailCubit(FakeProductRepository(), 1);

    expect(cubit.state.status, ProductDetailStatus.loading);
  });

  test('load emits the product when it exists', () async {
    final repository = FakeProductRepository([
      const Product(id: 1, name: 'Laptop'),
    ]);
    final cubit = ProductDetailCubit(repository, 1);

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.loaded);
    expect(cubit.state.product?.name, 'Laptop');
  });

  test('load emits notFound when the product does not exist', () async {
    final cubit = ProductDetailCubit(FakeProductRepository(), 99);

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.notFound);
    expect(cubit.state.product, isNull);
  });

  test('load emits error when the repository fails', () async {
    final repository = FakeProductRepository()..throwOnGetById = true;
    final cubit = ProductDetailCubit(repository, 1);

    await cubit.load();

    expect(cubit.state.status, ProductDetailStatus.error);
  });

  test('delete returns true and removes the product', () async {
    final repository = FakeProductRepository([
      const Product(id: 1, name: 'Laptop'),
    ]);
    final cubit = ProductDetailCubit(repository, 1);

    final success = await cubit.delete();

    expect(success, isTrue);
    expect(repository.products, isEmpty);
  });

  test('delete returns false when the repository fails', () async {
    final repository = FakeProductRepository([
      const Product(id: 1, name: 'Laptop'),
    ])..throwOnDelete = true;
    final cubit = ProductDetailCubit(repository, 1);

    final success = await cubit.delete();

    expect(success, isFalse);
    expect(repository.products.length, 1);
  });
}
