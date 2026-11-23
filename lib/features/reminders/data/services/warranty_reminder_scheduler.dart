import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/reminder_type.dart';
import '../../domain/repositories/reminder_settings_repository.dart';
import '../../domain/services/reminder_scheduler.dart';
import '../../domain/services/warranty_reminder_planner.dart';
import 'warranty_notification_gateway.dart';

class WarrantyReminderScheduler implements ReminderScheduler {
  WarrantyReminderScheduler({
    required ReminderSettingsRepository settingsRepository,
    required WarrantyNotificationGateway gateway,
    required ProductRepository productRepository,
    WarrantyReminderPlanner? planner,
    DateTime Function()? now,
  }) : _settingsRepository = settingsRepository,
       _gateway = gateway,
       _productRepository = productRepository,
       _planner = planner ?? const WarrantyReminderPlanner(),
       _now = now ?? DateTime.now;

  final ReminderSettingsRepository _settingsRepository;
  final WarrantyNotificationGateway _gateway;
  final ProductRepository _productRepository;
  final WarrantyReminderPlanner _planner;
  final DateTime Function() _now;

  @override
  Future<void> sync() async {
    try {
      final settings = await _settingsRepository.load();

      // Resync by construction: stale reminders are removed even when the
      // user has disabled notifications or lost permission.
      await _gateway.cancelAll();

      if (!settings.enabled || !await _gateway.hasPermission()) {
        return;
      }

      final products = await _productRepository.getAll();
      final plan = _planner.plan(
        products: products,
        settings: settings,
        now: _now(),
      );

      for (final reminder in plan) {
        await _gateway.schedule(
          reminder,
          title: _title(
            reminder.type,
          ).tr(namedArgs: {'productName': reminder.productName}),
          body: _body(reminder.type).tr(
            namedArgs: {
              'productName': reminder.productName,
              'days': settings.leadDays.toString(),
            },
          ),
        );
      }
    } catch (error) {
      // A product mutation must never fail because of notifications.
      debugPrint('WarrantyReminderScheduler: sync failed: $error');
    }
  }

  static String _title(ReminderType type) {
    return switch (type) {
      ReminderType.approaching => 'reminders.notification.approaching.title',
      ReminderType.expiration => 'reminders.notification.expiration.title',
    };
  }

  static String _body(ReminderType type) {
    return switch (type) {
      ReminderType.approaching => 'reminders.notification.approaching.body',
      ReminderType.expiration => 'reminders.notification.expiration.body',
    };
  }
}
