import 'reminder_type.dart';

class WarrantyReminder {
  const WarrantyReminder({
    required this.notificationId,
    required this.productId,
    required this.productName,
    required this.scheduledAt,
    required this.type,
  });

  final int notificationId;
  final int productId;
  final String productName;
  final DateTime scheduledAt;
  final ReminderType type;
}
