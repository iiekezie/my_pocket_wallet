import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:rxdart/subjects.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationFunctions {
  static final notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel id',
        'channel name',
        importance: Importance.max,
        priority: Priority.max,
      ),
    );
  }

  //initialization of the notification
  static Future init({bool initScheduled = false}) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windows = WindowsInitializationSettings(
      appName: 'MyWallet',
      appUserModelId: 'com.fouvty.mywallet',
      guid: 'a2b1c3d4-e5f6-4123-a456-789012345678',
    );
    const settings = InitializationSettings(android: android, windows: windows);

    await notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        onNotifications.add(response.payload);
      },
    );
    if (initScheduled) {
      try {
        tz.initializeTimeZones();
        final loactionName = await FlutterNativeTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(loactionName));
      } catch (e) {
        // Timezone initialization not supported on this platform
        // Fallback to UTC
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  // //delete all notifications
  static Future<void> deleteAllNotifications() async {
    await notifications.cancelAll();
  }

  //show notification
  static Future showNotification(
          {int id = 0,
          String? title,
          String? body,
          String? payload,
          required int selectedHour,
          required int selectedMinute}) async =>
      notifications.zonedSchedule(
        id,
        title,
        body,
        scheduleDaily(selectedHour, selectedMinute),
        await notificationDetails(),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

  //schedule daily notification
  static tz.TZDateTime scheduleDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );
    return scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;
  }
}
