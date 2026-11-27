import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/warranty_reminder.dart';

/// Platform boundary for local notifications. Implemented with the
/// flutter_local_notifications plugin and replaceable in tests.
abstract class WarrantyNotificationGateway {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<bool> hasPermission();

  Future<void> cancelAll();

  Future<void> schedule(
    WarrantyReminder reminder, {
    required String title,
    required String body,
  });

  Future<bool> openSystemNotificationSettings();

  Future<List<PendingNotificationRequest>> getPendingReminders();
}
