import 'package:get_it/get_it.dart';
import 'package:warranty_tracker/core/database/app_database.dart';

final GetIt getIt = GetIt.instance;

void setupInjection() {
  getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
}
