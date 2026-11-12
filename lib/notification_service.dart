import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Called when a user taps on a notification.
  // Payloads are used to identify the related task or schedule.
  static void Function(String? payload)? onNotificationTap;

  // Use exact alarms when permission is available.
  // Otherwise, Android will use inexact alarms.
  static AndroidScheduleMode _scheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'lifezen_reminders',
      'LifeZen Reminders',
      channelDescription: 'Task and schedule reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static Future<void> init() async {
    tz.initializeTimeZones();

    // Get the device timezone so notifications follow the user's
    // local time, even when they travel.
    try {
      final deviceTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTz.identifier));
    } catch (_) {
      // Use Kuala Lumpur timezone if the device timezone is unavailable.
      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    // Check whether Android allows exact alarms.
    try {
      final canExact = await androidPlugin?.canScheduleExactNotifications();

      if (canExact == true) {
        _scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {
      // Keep using inexact alarms if the check is unavailable.
    }
  }

  // ==========================================================
  // TEST NOTIFICATION
  // ==========================================================

  static Future<void> testNotification() async {
    await _plugin.show(
      id: 999,
      title: 'LifeZen Test',
      body: 'Notifications are working!',
      notificationDetails: _notificationDetails,
    );
  }

  // ==========================================================
  // TASK NOTIFICATION
  // ==========================================================

  static Future<void> scheduleTask({
    required int id,
    required String title,
    required DateTime dateTime,
    int? reminderMinutes = 10,
    String? payload,
    String? detail,
  }) async {
    // Skip the reminder if it is disabled.
    if (reminderMinutes == null || reminderMinutes < 0) return;

    final reminder = dateTime.subtract(Duration(minutes: reminderMinutes));

    // No need to schedule a notification if its time has passed.
    if (!reminder.isAfter(DateTime.now())) {
      return;
    }

    await _schedule(
      id: id,
      title: title,
      body: detail ?? 'Reminder',
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      payload: payload,
    );
  }

  // ==========================================================
  // WEEKLY SCHEDULE NOTIFICATION
  // ==========================================================

  static Future<void> scheduleWeekly({
    required int id,
    required String title,
    required int weekday,
    required int hour,
    required int minute,
    int? reminderMinutes = 10,
    String? payload,
    String? detail,
  }) async {
    // Skip the reminder if it is disabled.
    if (reminderMinutes == null || reminderMinutes < 0) return;

    final now = tz.TZDateTime.now(tz.local);

    // Find the next matching weekday.
    int daysUntil = weekday - now.weekday;

    if (daysUntil < 0) {
      daysUntil += 7;
    }

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: daysUntil));

    // If the selected time has already passed today,
    // move the notification to the following week.
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    final reminder = scheduled.subtract(Duration(minutes: reminderMinutes));

    // Move to next week if the reminder time has already passed.
    if (!reminder.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _schedule(
      id: id,
      title: title,
      body:
          detail ??
          'Starts ${hour.toString().padLeft(2, '0')}:'
              '${minute.toString().padLeft(2, '0')}',
      scheduledDate: tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        scheduled.hour,
        scheduled.minute,
      ).subtract(Duration(minutes: reminderMinutes)),
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ==========================================================
  // SCHEDULER
  // ==========================================================

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails,
        androidScheduleMode: mode,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    }

    try {
      await schedule(_scheduleMode);
    } on PlatformException {
      // Switch to inexact alarms if Android blocks exact alarms.
      _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      await schedule(_scheduleMode);
    } catch (e) {
      // Try inexact alarms if scheduling fails for another reason.
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  // ==========================================================
  // CANCEL NOTIFICATIONS
  // ==========================================================

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
