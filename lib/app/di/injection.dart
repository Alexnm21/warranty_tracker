import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../features/products/data/daos/product_dao.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/presentation/bloc/product_list_cubit.dart';

final GetIt getIt = GetIt.instance;

void setupInjection({AppDatabase? database}) {
  getIt.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());

  getIt.registerLazySingleton<ProductDao>(
    () => ProductDao(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductDao>()),
  );

  getIt.registerFactory<ProductListCubit>(
    () => ProductListCubit(getIt<ProductRepository>()),
  );
}
