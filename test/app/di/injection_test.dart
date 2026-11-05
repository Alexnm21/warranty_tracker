import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/core/database/app_database.dart';
import 'package:warranty_tracker/features/documents/data/daos/document_dao.dart';
import 'package:warranty_tracker/features/documents/data/services/document_file_storage.dart';
import 'package:warranty_tracker/features/documents/domain/repositories/document_repository.dart';
import 'package:warranty_tracker/features/products/data/daos/product_dao.dart';
import 'package:warranty_tracker/features/products/domain/repositories/product_repository.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test('setupInjection registers AppDatabase', () {
    setupInjection();

    expect(getIt.isRegistered<AppDatabase>(), isTrue);
  });

  test('setupInjection registers product data dependencies', () {
    setupInjection();

    expect(getIt.isRegistered<ProductDao>(), isTrue);
    expect(getIt.isRegistered<ProductRepository>(), isTrue);
  });

  test('setupInjection registers document data dependencies', () {
    setupInjection();

    expect(getIt.isRegistered<DocumentDao>(), isTrue);
    expect(getIt.isRegistered<DocumentFileStorage>(), isTrue);
    expect(getIt.isRegistered<DocumentRepository>(), isTrue);
  });
}
