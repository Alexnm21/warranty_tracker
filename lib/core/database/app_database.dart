import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/product_documents_table.dart';
import 'tables/products_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Products, ProductDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'warranty_tracker');
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // The warranty start date was replaced by the purchase date, so the
        // column is no longer part of the model. Dropping it keeps the stored
        // rows intact.
        await m.database.customStatement(
          'ALTER TABLE products DROP COLUMN warranty_start_date',
        );
      }
      if (from < 3) {
        await m.createTable(productDocuments);
      }
    },
    beforeOpen: (details) async {
      // Required for the product documents foreign key cascade.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
