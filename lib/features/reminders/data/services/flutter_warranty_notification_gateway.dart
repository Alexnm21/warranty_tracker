import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/warranty_reminder.dart';
import 'warranty_notification_gateway.dart';

/// Local notification gateway backed by flutter_local_notifications.
///
/// The plugin, timezone lookup and timezone data loader are injectable so the
/// gateway can be tested without native channels.
class FlutterWarrantyNotificationGateway
    implements WarrantyNotificationGateway {
  FlutterWarrantyNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? localTimeZoneName,
    void Function()? initializeTimeZones,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localTimeZoneName = localTimeZoneName ?? _deviceTimeZoneName,
       _initializeTimeZones =
           initializeTimeZones ?? tz_data.initializeTimeZones;

  static const String _channelId = 'warranty_reminders';
  static const String _channelName = 'Warranty reminders';
  static const String _channelDescription = 'Reminders for warranty dates';
  static const String _notificationIcon = 'ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _localTimeZoneName;
  final void Function() _initializeTimeZones;

  static Future<String> _deviceTimeZoneName() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  }

  @override
  Future<void> initialize() async {
    _initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _localTimeZoneName()));

    // Permissions are requested only from an explicit user action.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_notificationIcon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    }

    return false;
  }

  @override
  Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.checkPermissions().then(
        (options) => options?.isEnabled ?? false,
      );
    }

    return false;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(
    WarrantyReminder reminder, {
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminder.scheduledAt, tz.local),
      payload: '${reminder.productId}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<bool> openSystemNotificationSettings() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.openAppNotificationSettings() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.openAppNotificationSettings() ?? false;
    }

    return false;
  }
}
