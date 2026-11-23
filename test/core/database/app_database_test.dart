import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/core/database/app_database.dart';

void main() {
  test('AppDatabase opens and runs a query', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final row = await db.customSelect('SELECT 1 AS value').getSingle();

    expect(row.data['value'], 1);

    await db.close();
  });

  test('creates the product documents table', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    expect(await db.select(db.productDocuments).get(), isEmpty);

    await db.close();
  });

  test('deleting a product cascades to its documents', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime(2025, 1, 1);

    final productId = await db
        .into(db.products)
        .insert(
          ProductsCompanion.insert(
            name: 'Laptop',
            purchaseDate: now,
            warrantyEndDate: DateTime(2026, 1, 1),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.productDocuments)
        .insert(
          ProductDocumentsCompanion.insert(
            productId: productId,
            fileName: 'receipt.pdf',
            storagePath: 'warranty_documents/$productId/receipt.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 1024,
            source: 'file',
            createdAt: now,
          ),
        );

    await (db.delete(
      db.products,
    )..where((table) => table.id.equals(productId))).go();

    expect(await db.select(db.productDocuments).get(), isEmpty);

    await db.close();
  });

  test('migrates a v2 database to v3 without losing products', () async {
    final directory = await Directory.systemTemp.createTemp(
      'warranty_db_migration',
    );
    final file = File('${directory.path}/app.sqlite');

    final db = AppDatabase.forTesting(
      NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('''
            CREATE TABLE IF NOT EXISTS products (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              brand TEXT NULL,
              model TEXT NULL,
              store TEXT NULL,
              purchase_date DATETIME NOT NULL,
              price INTEGER NULL,
              currency TEXT NULL,
              serial_number TEXT NULL,
              warranty_end_date DATETIME NOT NULL,
              notes TEXT NULL,
              created_at DATETIME NOT NULL,
              updated_at DATETIME NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO products (
              name, purchase_date, warranty_end_date, created_at, updated_at
            ) VALUES ('Laptop', 1735689600, 1767225600, 1735689600, 1735689600)
          ''');
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );

    final products = await db.select(db.products).get();

    expect(products, hasLength(1));
    expect(products.single.name, 'Laptop');
    expect(await db.select(db.productDocuments).get(), isEmpty);

    await db.close();
    await directory.delete(recursive: true);
  });
}
