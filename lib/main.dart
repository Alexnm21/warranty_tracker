import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:warranty_tracker/app/app.dart';
import 'package:warranty_tracker/app/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  setupInjection();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const App(),
    ),
  );
}
