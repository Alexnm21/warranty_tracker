import 'package:drift/drift.dart';

import 'products_table.dart';

/// Documents associated with a product, such as receipts, invoices or
/// warranty evidence.
///
/// Only metadata is stored in SQLite. The files themselves live in the
/// application documents directory and are referenced through `storagePath`.
@DataClassName('ProductDocumentRow')
class ProductDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();

  /// Original file name shown to the user.
  TextColumn get fileName => text()();

  /// Path relative to the application documents directory.
  TextColumn get storagePath => text()();

  TextColumn get mimeType => text()();

  IntColumn get sizeBytes => integer()();

  /// How the document was added: `scan`, `photo` or `file`.
  TextColumn get source => text()();

  DateTimeColumn get createdAt => dateTime()();
}
