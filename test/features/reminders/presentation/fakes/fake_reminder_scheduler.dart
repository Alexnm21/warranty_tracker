import 'package:warranty_tracker/features/reminders/domain/services/reminder_scheduler.dart';

class FakeReminderScheduler implements ReminderScheduler {
  int syncCount = 0;

  @override
  Future<void> sync() async => syncCount++;
}
