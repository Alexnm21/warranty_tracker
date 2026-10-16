import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/products/data/mappers/product_mapper.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';

void main() {
  final purchaseDate = DateTime(2026, 1, 5);
  final start = DateTime(2026, 1, 5);
  final end = DateTime(2027, 1, 5);
  final createdAt = DateTime(2026, 1, 5, 10);
  final updatedAt = DateTime(2026, 1, 6, 11);

  ProductRow buildRow() {
    return ProductRow(
      id: 1,
      name: 'Laptop',
      brand: 'Lenovo',
      model: 'ThinkPad',
      store: 'Acme',
      purchaseDate: purchaseDate,
      price: 89999,
      currency: 'EUR',
      serialNumber: 'SN-123',
      warrantyStartDate: start,
      warrantyEndDate: end,
      notes: 'Some notes',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  group('ProductMapper.toEntity', () {
    test('maps every column to the entity', () {
      final product = ProductMapper.toEntity(buildRow());

      expect(product.id, 1);
      expect(product.name, 'Laptop');
      expect(product.brand, 'Lenovo');
      expect(product.model, 'ThinkPad');
      expect(product.store, 'Acme');
      expect(product.purchaseDate, purchaseDate);
      expect(product.price, 89999);
      expect(product.currency, 'EUR');
      expect(product.serialNumber, 'SN-123');
      expect(product.warrantyStartDate, start);
      expect(product.warrantyEndDate, end);
      expect(product.notes, 'Some notes');
      expect(product.createdAt, createdAt);
      expect(product.updatedAt, updatedAt);
    });
  });

  group('ProductMapper.toRow', () {
    test('maps the entity back to every column', () {
      final row = ProductMapper.toRow(
        Product(
          id: 1,
          name: 'Laptop',
          brand: 'Lenovo',
          model: 'ThinkPad',
          store: 'Acme',
          purchaseDate: purchaseDate,
          price: 89999,
          currency: 'EUR',
          serialNumber: 'SN-123',
          warrantyStartDate: start,
          warrantyEndDate: end,
          notes: 'Some notes',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );

      expect(row.id, 1);
      expect(row.name, 'Laptop');
      expect(row.brand, 'Lenovo');
      expect(row.model, 'ThinkPad');
      expect(row.store, 'Acme');
      expect(row.purchaseDate, purchaseDate);
      expect(row.price, 89999);
      expect(row.currency, 'EUR');
      expect(row.serialNumber, 'SN-123');
      expect(row.warrantyStartDate, start);
      expect(row.warrantyEndDate, end);
      expect(row.notes, 'Some notes');
      expect(row.createdAt, createdAt);
      expect(row.updatedAt, updatedAt);
    });

    test('keeps optional columns null', () {
      final row = ProductMapper.toRow(
        Product(
          id: 2,
          name: 'Charger',
          purchaseDate: purchaseDate,
          warrantyStartDate: start,
          warrantyEndDate: end,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );

      expect(row.brand, isNull);
      expect(row.model, isNull);
      expect(row.store, isNull);
      expect(row.price, isNull);
      expect(row.currency, isNull);
      expect(row.serialNumber, isNull);
      expect(row.notes, isNull);
    });
  });

  group('ProductMapper.toInsertCompanion', () {
    test('maps required and optional values', () {
      final companion = ProductMapper.toInsertCompanion(
        Product(
          name: 'Laptop',
          brand: 'Lenovo',
          purchaseDate: purchaseDate,
          price: 89999,
          currency: 'EUR',
          warrantyStartDate: start,
          warrantyEndDate: end,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );

      expect(companion.name.value, 'Laptop');
      expect(companion.brand.value, 'Lenovo');
      expect(companion.purchaseDate.value, purchaseDate);
      expect(companion.price.value, 89999);
      expect(companion.currency.value, 'EUR');
      expect(companion.warrantyStartDate.value, start);
      expect(companion.warrantyEndDate.value, end);
    });
  });
}
