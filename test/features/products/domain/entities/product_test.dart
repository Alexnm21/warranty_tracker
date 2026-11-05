import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/products/domain/entities/warranty_status.dart';

void main() {
  final today = DateTime.now();

  group('Product.warrantyStatus', () {
    test('is active between the purchase date and the warranty end date', () {
      final product = Product(
        name: 'Laptop',
        purchaseDate: today.subtract(const Duration(days: 1)),
        warrantyEndDate: today.add(const Duration(days: 1)),
      );

      expect(product.warrantyStatus, WarrantyStatus.active);
    });

    test('is expired when the warranty end date has passed', () {
      final product = Product(
        name: 'Laptop',
        purchaseDate: today.subtract(const Duration(days: 30)),
        warrantyEndDate: today.subtract(const Duration(days: 1)),
      );

      expect(product.warrantyStatus, WarrantyStatus.expired);
    });

    test('is future when the purchase date has not happened yet', () {
      final product = Product(
        name: 'Laptop',
        purchaseDate: today.add(const Duration(days: 1)),
        warrantyEndDate: today.add(const Duration(days: 30)),
      );

      expect(product.warrantyStatus, WarrantyStatus.future);
    });

    test('is active on the warranty end date', () {
      final product = Product(
        name: 'Laptop',
        purchaseDate: today.subtract(const Duration(days: 30)),
        warrantyEndDate: today,
      );

      expect(product.warrantyStatus, WarrantyStatus.active);
    });
  });
}
