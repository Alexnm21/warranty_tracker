import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:warranty_tracker/features/reminders/data/services/warranty_notification_gateway.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/warranty_reminder.dart';

class FakeWarrantyNotificationGateway implements WarrantyNotificationGateway {
  bool permission = true;
  bool requestResult = true;
  int permissionRequests = 0;
  int settingsOpenings = 0;
  List<PendingNotificationRequest> pending = const [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return requestResult;
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> schedule(
    WarrantyReminder reminder, {
    required String title,
    required String body,
  }) async {}

  @override
  Future<bool> openSystemNotificationSettings() async {
    settingsOpenings++;
    return true;
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return List<PendingNotificationRequest>.unmodifiable(pending);
  }
}
