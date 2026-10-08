import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:warranty_tracker/app/di/injection.dart';
import 'package:warranty_tracker/core/database/app_database.dart';

void main() {
  tearDown(() => GetIt.instance.reset());

  test('setupInjection registers AppDatabase', () {
    setupInjection();

    expect(getIt.isRegistered<AppDatabase>(), isTrue);
    expect(getIt<AppDatabase>(), isA<AppDatabase>());
  });
}
