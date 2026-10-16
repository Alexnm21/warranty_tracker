import 'warranty_status.dart';

class Product {
  const Product({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.store,
    this.purchaseDate,
    this.price,
    this.currency,
    this.serialNumber,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? brand;
  final String? model;
  final String? store;
  final DateTime? purchaseDate;
  final int? price;
  final String? currency;
  final String? serialNumber;
  final DateTime? warrantyStartDate;
  final DateTime? warrantyEndDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WarrantyStatus get warrantyStatus {
    return WarrantyStatus.fromDates(warrantyStartDate, warrantyEndDate);
  }

  Product copyWith({
    int? id,
    String? name,
    String? brand,
    String? model,
    String? store,
    DateTime? purchaseDate,
    int? price,
    String? currency,
    String? serialNumber,
    DateTime? warrantyStartDate,
    DateTime? warrantyEndDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      store: store ?? this.store,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      serialNumber: serialNumber ?? this.serialNumber,
      warrantyStartDate: warrantyStartDate ?? this.warrantyStartDate,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
