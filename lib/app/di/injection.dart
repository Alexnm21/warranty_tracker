import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../features/products/data/daos/product_dao.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';

final GetIt getIt = GetIt.instance;

void setupInjection() {
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);

  getIt.registerLazySingleton<ProductDao>(
    () => ProductDao(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductDao>()),
  );
}
