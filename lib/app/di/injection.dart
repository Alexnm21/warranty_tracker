import 'package:get_it/get_it.dart';

import '../../core/database/app_database.dart';
import '../../features/documents/data/daos/document_dao.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/data/services/document_file_storage.dart';
import '../../features/documents/data/services/document_importer.dart';
import '../../features/documents/data/services/document_opener.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/products/data/daos/product_dao.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/presentation/bloc/product_detail_cubit.dart';
import '../../features/products/presentation/bloc/product_form_cubit.dart';
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

  getIt.registerLazySingleton<DocumentDao>(
    () => DocumentDao(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<DocumentFileStorage>(() => DocumentFileStorage());
  getIt.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      getIt<DocumentDao>(),
      getIt<DocumentFileStorage>(),
    ),
  );
  getIt.registerLazySingleton<DocumentImporter>(
    () => DocumentImporter(storage: getIt<DocumentFileStorage>()),
  );
  getIt.registerLazySingleton<DocumentOpener>(() => DocumentOpener());

  getIt.registerFactory<ProductListCubit>(
    () => ProductListCubit(getIt<ProductRepository>()),
  );
  getIt.registerFactoryParam<ProductDetailCubit, int, void>(
    (productId, _) => ProductDetailCubit(getIt<ProductRepository>(), productId),
  );

  getIt.registerFactoryParam<ProductFormCubit, int?, void>(
    (productId, _) => ProductFormCubit(
      repository: getIt<ProductRepository>(),
      documentRepository: getIt<DocumentRepository>(),
      documentImporter: getIt<DocumentImporter>(),
      documentOpener: getIt<DocumentOpener>(),
      productId: productId,
    ),
  );
}
