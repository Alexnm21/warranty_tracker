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
import '../../features/reminders/data/repositories/reminder_settings_repository_impl.dart';
import '../../features/reminders/data/services/flutter_warranty_notification_gateway.dart';
import '../../features/reminders/data/services/warranty_notification_gateway.dart';
import '../../features/reminders/data/services/warranty_reminder_scheduler.dart';
import '../../features/reminders/domain/repositories/reminder_settings_repository.dart';
import '../../features/reminders/domain/services/reminder_scheduler.dart';

final GetIt getIt = GetIt.instance;

void setupInjection({AppDatabase? database}) {
  getIt.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());

  getIt.registerLazySingleton<ProductDao>(
    () => ProductDao(getIt<AppDatabase>()),
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

  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      getIt<ProductDao>(),
      getIt<DocumentRepository>(),
      // Resolved on demand: the scheduler itself reads ProductRepository.
      reminderSync: () => getIt<ReminderScheduler>().sync(),
    ),
  );
  getIt.registerLazySingleton<DocumentImporter>(
    () => DocumentImporter(storage: getIt<DocumentFileStorage>()),
  );
  getIt.registerLazySingleton<DocumentOpener>(() => DocumentOpener());

  getIt.registerLazySingleton<ReminderSettingsRepository>(
    () => ReminderSettingsRepositoryImpl(),
  );
  getIt.registerLazySingleton<WarrantyNotificationGateway>(
    () => FlutterWarrantyNotificationGateway(),
  );
  getIt.registerLazySingleton<ReminderScheduler>(
    () => WarrantyReminderScheduler(
      settingsRepository: getIt<ReminderSettingsRepository>(),
      gateway: getIt<WarrantyNotificationGateway>(),
      productRepository: getIt<ProductRepository>(),
    ),
  );

  getIt.registerFactory<ProductListCubit>(
    () => ProductListCubit(getIt<ProductRepository>()),
  );
  getIt.registerFactoryParam<ProductDetailCubit, int, void>(
    (productId, _) => ProductDetailCubit(
      repository: getIt<ProductRepository>(),
      documentRepository: getIt<DocumentRepository>(),
      documentOpener: getIt<DocumentOpener>(),
      productId: productId,
    ),
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
