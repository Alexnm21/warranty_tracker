import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_list_cubit.dart';
import 'package:warranty_tracker/features/products/presentation/bloc/product_list_state.dart';

import '../fakes/fake_product_repository.dart';

void main() {
  Product product(int id, String name) => Product(id: id, name: name);

  test('starts in the loading state', () {
    final cubit = ProductListCubit(FakeProductRepository());

    expect(cubit.state.status, ProductListStatus.loading);
  });

  test('load emits the products on success', () async {
    final repository = FakeProductRepository([
      product(1, 'Laptop'),
      product(2, 'Phone'),
    ]);
    final cubit = ProductListCubit(repository);

    await cubit.load();

    expect(cubit.state.status, ProductListStatus.loaded);
    expect(cubit.state.products.map((p) => p.name), ['Laptop', 'Phone']);
  });

  test('load emits error when the repository fails', () async {
    final repository = FakeProductRepository()..throwOnGetAll = true;
    final cubit = ProductListCubit(repository);

    await cubit.load();

    expect(cubit.state.status, ProductListStatus.error);
  });

  test('search filters products and keeps the query', () async {
    final repository = FakeProductRepository([
      product(1, 'Laptop'),
      product(2, 'Phone'),
    ]);
    final cubit = ProductListCubit(repository);

    await cubit.search('phone');

    expect(cubit.state.status, ProductListStatus.loaded);
    expect(cubit.state.query, 'phone');
    expect(cubit.state.products.map((p) => p.name), ['Phone']);
  });

  test('search with an empty query returns every product', () async {
    final repository = FakeProductRepository([
      product(1, 'Laptop'),
      product(2, 'Phone'),
    ]);
    final cubit = ProductListCubit(repository);

    await cubit.search('');

    expect(cubit.state.products.length, 2);
  });

  test('delete removes the product and reloads the list', () async {
    final repository = FakeProductRepository([
      product(1, 'Laptop'),
      product(2, 'Phone'),
    ]);
    final cubit = ProductListCubit(repository);

    final success = await cubit.delete(1);

    expect(success, isTrue);
    expect(cubit.state.products.map((p) => p.name), ['Phone']);
  });

  test('delete returns false and keeps the state on failure', () async {
    final repository = FakeProductRepository([product(1, 'Laptop')])
      ..throwOnDelete = true;
    final cubit = ProductListCubit(repository);
    await cubit.load();

    final success = await cubit.delete(1);

    expect(success, isFalse);
    expect(cubit.state.status, ProductListStatus.loaded);
    expect(cubit.state.products.length, 1);
  });
}
