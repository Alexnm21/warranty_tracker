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
}
