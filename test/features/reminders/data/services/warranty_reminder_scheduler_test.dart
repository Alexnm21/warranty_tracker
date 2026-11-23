import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_tracker/features/products/domain/entities/product.dart';
import 'package:warranty_tracker/features/reminders/data/services/warranty_notification_gateway.dart';
import 'package:warranty_tracker/features/reminders/data/services/warranty_reminder_scheduler.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/reminder_settings.dart';
import 'package:warranty_tracker/features/reminders/domain/entities/warranty_reminder.dart';
import 'package:warranty_tracker/features/reminders/domain/repositories/reminder_settings_repository.dart';

import '../../../products/presentation/fakes/fake_product_repository.dart';

class FakeSettingsRepository implements ReminderSettingsRepository {
  FakeSettingsRepository(this.settings);

  ReminderSettings settings;

  @override
  Future<ReminderSettings> load() async => settings;

  @override
  Future<void> save(ReminderSettings value) async {
    settings = value;
  }
}

class FakeGateway implements WarrantyNotificationGateway {
  bool permission = true;
  bool throwOnSchedule = false;
  int cancelCount = 0;
  final List<WarrantyReminder> scheduled = [];
  final List<String> titles = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permission;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> cancelAll() async => cancelCount++;

  @override
  Future<void> schedule(
    WarrantyReminder reminder, {
    required String title,
    required String body,
  }) async {
    if (throwOnSchedule) {
      throw Exception('Scheduling failed');
    }
    scheduled.add(reminder);
    titles.add(title);
  }

  @override
  Future<bool> openSystemNotificationSettings() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 1, 1, 8);
  final product = Product(
    id: 1,
    name: 'Laptop',
    warrantyEndDate: DateTime(2026, 2, 1),
  );
  final enabledSettings = ReminderSettings(enabled: true, leadDays: 30);

  WarrantyReminderScheduler schedulerFor(
    ReminderSettings settings,
    FakeGateway gateway,
  ) {
    return WarrantyReminderScheduler(
      settingsRepository: FakeSettingsRepository(settings),
      gateway: gateway,
      productRepository: FakeProductRepository([product]),
      now: () => now,
    );
  }

  group('WarrantyReminderScheduler.sync', () {
    test('cancels pending reminders when notifications are disabled', () async {
      final gateway = FakeGateway();

      await schedulerFor(ReminderSettings(), gateway).sync();

      expect(gateway.cancelCount, 1);
      expect(gateway.scheduled, isEmpty);
    });

    test('cancels pending reminders when permission is denied', () async {
      final gateway = FakeGateway()..permission = false;

      await schedulerFor(enabledSettings, gateway).sync();

      expect(gateway.cancelCount, 1);
      expect(gateway.scheduled, isEmpty);
    });

    test('schedules the planned reminders with localized messages', () async {
      final gateway = FakeGateway();

      await schedulerFor(enabledSettings, gateway).sync();

      expect(gateway.scheduled.map((reminder) => reminder.notificationId), [
        2,
        3,
      ]);
      expect(gateway.titles, [
        'reminders.notification.approaching.title',
        'reminders.notification.expiration.title',
      ]);
    });

    test('does not propagate scheduling failures', () async {
      final gateway = FakeGateway()..throwOnSchedule = true;

      await schedulerFor(enabledSettings, gateway).sync();

      expect(gateway.cancelCount, 1);
      expect(gateway.scheduled, isEmpty);
    });
  });
}
