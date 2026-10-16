import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/product.dart';

abstract final class ProductMapper {
  static Product toEntity(ProductRow row) {
    return Product(
      id: row.id,
      name: row.name,
      brand: row.brand,
      model: row.model,
      store: row.store,
      purchaseDate: row.purchaseDate,
      price: row.price,
      currency: row.currency,
      serialNumber: row.serialNumber,
      warrantyStartDate: row.warrantyStartDate,
      warrantyEndDate: row.warrantyEndDate,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static ProductsCompanion toInsertCompanion(Product product) {
    return ProductsCompanion.insert(
      id: product.id == null ? const Value.absent() : Value(product.id!),
      name: product.name,
      purchaseDate: product.purchaseDate!,
      warrantyStartDate: product.warrantyStartDate!,
      warrantyEndDate: product.warrantyEndDate!,
      createdAt: product.createdAt!,
      updatedAt: product.updatedAt!,
      brand: Value(product.brand),
      model: Value(product.model),
      store: Value(product.store),
      price: Value(product.price),
      currency: Value(product.currency),
      serialNumber: Value(product.serialNumber),
      notes: Value(product.notes),
    );
  }

  static ProductRow toRow(Product product) {
    return ProductRow(
      id: product.id!,
      name: product.name,
      purchaseDate: product.purchaseDate!,
      warrantyStartDate: product.warrantyStartDate!,
      warrantyEndDate: product.warrantyEndDate!,
      createdAt: product.createdAt!,
      updatedAt: product.updatedAt!,
      brand: product.brand,
      model: product.model,
      store: product.store,
      price: product.price,
      currency: product.currency,
      serialNumber: product.serialNumber,
      notes: product.notes,
    );
  }
}
