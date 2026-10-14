import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Invoked when the user taps a scheduled notification.
  /// The payload format is set by scheduleTask / scheduleWeekly callers:
  /// `task:<id>` or `schedule:<id>:<weekday>`.
  static void Function(String? payload)? onNotificationTap;

  /// Exact alarms keep reminders on time (Android can batch/delay
  /// inexact ones by 15-30 min in Doze). Downgraded to inexact if the
  /// OS denies or later revokes the permission.
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

    // Use the device's real timezone so travelling users still get
    // reminders at the right local time; fall back to Kuala Lumpur
    // when the platform reports an ID the timezone DB lacks
    // (older Android returns raw "GMT+08:00"-style strings).
    try {
      final deviceTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTz.identifier));
    } catch (_) {
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

    // Prefer exact alarms so reminders arrive on time; the OS may deny
    // them (permission revoked by the user) — then keep inexact mode.
    try {
      final canExact = await androidPlugin?.canScheduleExactNotifications();
      if (canExact == true) {
        _scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {
      // Older OS or plugin without the API — inexact mode stays.
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
    // null / negative = no reminder for this item.
    if (reminderMinutes == null || reminderMinutes < 0) return;
    final reminder = dateTime.subtract(Duration(minutes: reminderMinutes));

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
    // null / negative = no reminder for this item.
    if (reminderMinutes == null || reminderMinutes < 0) return;
    final now = tz.TZDateTime.now(tz.local);

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

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    final reminder = scheduled.subtract(Duration(minutes: reminderMinutes));

    // If the reminder has already passed, move it to next week.
    if (!reminder.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _schedule(
      id: id,
      title: title,
      body: detail ??
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
  // SCHEDULER (exact first, inexact fallback)
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
      // Exact-alarm permission denied or revoked — downgrade permanently
      // for this session so every later schedule still succeeds.
      _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      await schedule(_scheduleMode);
    } catch (e) {
      // Last resort: a late reminder beats no reminder.
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  // ==========================================================
  // CANCEL
  // ==========================================================

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
