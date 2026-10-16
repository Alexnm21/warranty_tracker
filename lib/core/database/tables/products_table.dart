import 'package:drift/drift.dart';

@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get brand => text().nullable()();

  TextColumn get model => text().nullable()();

  TextColumn get store => text().nullable()();

  DateTimeColumn get purchaseDate => dateTime()();

  IntColumn get price => integer().nullable()();

  TextColumn get currency => text().nullable()();

  TextColumn get serialNumber => text().nullable()();

  DateTimeColumn get warrantyStartDate => dateTime()();

  DateTimeColumn get warrantyEndDate => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
