import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'features/reminders/data/services/warranty_notification_gateway.dart';
import 'features/reminders/domain/services/reminder_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  setupInjection();
  await _bootstrapReminders();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const App(),
    ),
  );
}

/// Schedules reminders from the current data without blocking app startup on
/// notification plugin failures. Permission is not requested here.
Future<void> _bootstrapReminders() async {
  try {
    await getIt<WarrantyNotificationGateway>().initialize();
    await getIt<ReminderScheduler>().sync();
  } catch (error) {
    debugPrint('Could not initialize warranty reminders: $error');
  }
}
