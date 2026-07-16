import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationIds {
  static const int dailyReminder = 1;
  static const int streakAlert = 2;
  static const int studyTip = 3;

  static const dailyTypes = [dailyReminder, streakAlert, studyTip];
  static const all = dailyTypes;
}

class StudyTips {
  static const tips = [
    'Use spaced repetition — review material at increasing intervals.',
    'Try active recall — test yourself without notes instead of re-reading.',
    'The Pomodoro technique — focused work, then a short break.',
    'Teach what you learned — explaining a topic reveals gaps in understanding.',
    'Mix subjects intentionally — interleaving improves long-term retention.',
    'Eliminate distractions — put your phone away before starting a session.',
    'Start with your hardest task when your energy is highest.',
    'Take handwritten notes — writing helps you process and remember concepts.',
    'Sleep on it — rest consolidates what you studied today.',
    'Set a specific goal for each session instead of vague "study math."',
    'Use practice problems — applying concepts beats memorizing alone.',
    'Break big topics into small chunks that feel manageable.',
    'Review mistakes carefully — errors show where understanding is weak.',
    'Study in a consistent place to signal your brain it is focus time.',
    'Stay hydrated and take short movement breaks to reset attention.',
  ];

  static String forDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return tips[dayOfYear % tips.length];
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _androidPermissionChannel =
      MethodChannel('study_coach_app/notifications');

  static const int _androidApiTiramisu = 33;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('[NotificationService] Resolved timezone name: $timeZoneName');
    } catch (e, stackTrace) {
      debugPrint(
          '[NotificationService] Failed to get local timezone, defaulting to UTC: $e\n$stackTrace');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) return null;
    try {
      final sdk = await _androidPermissionChannel.invokeMethod<int>(
        'getAndroidSdkInt',
      );
      debugPrint('[NotificationService] Android SDK int: $sdk');
      return sdk;
    } catch (e, stackTrace) {
      debugPrint(
        '[NotificationService] getAndroidSdkInt failed: $e\n$stackTrace',
      );
      return null;
    }
  }

  Future<bool?> _isPostNotificationsGranted() async {
    if (!Platform.isAndroid) return null;
    try {
      final granted = await _androidPermissionChannel.invokeMethod<bool>(
        'isPostNotificationsGranted',
      );
      debugPrint(
        '[NotificationService] POST_NOTIFICATIONS granted (raw): $granted',
      );
      return granted;
    } catch (e, stackTrace) {
      debugPrint(
        '[NotificationService] isPostNotificationsGranted failed: $e\n$stackTrace',
      );
      return null;
    }
  }

  Future<bool> hasPermission() async {
    debugPrint('[NotificationService] hasPermission: start');

    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final rawEnabled = await androidPlugin.areNotificationsEnabled();
      final osEnabled = rawEnabled ?? false;
      debugPrint(
        '[NotificationService] areNotificationsEnabled raw=$rawEnabled '
        'resolved=$osEnabled',
      );

      if (!osEnabled) {
        debugPrint(
          '[NotificationService] hasPermission: DENIED '
          '(OS notifications disabled)',
        );
        return false;
      }

      final sdk = await _androidSdkInt();
      if (sdk != null && sdk >= _androidApiTiramisu) {
        final rawPost = await _isPostNotificationsGranted();
        final postGranted = rawPost ?? false;
        debugPrint(
          '[NotificationService] POST_NOTIFICATIONS resolved=$postGranted',
        );
        if (!postGranted) {
          debugPrint(
            '[NotificationService] hasPermission: DENIED '
            '(POST_NOTIFICATIONS not granted on API $sdk)',
          );
          return false;
        }
      }

      debugPrint('[NotificationService] hasPermission: GRANTED (Android)');
      return true;
    }

    final iosPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final permissions = await iosPlugin.checkPermissions();
      final granted = permissions?.isEnabled ?? false;
      debugPrint(
        '[NotificationService] iOS checkPermissions isEnabled=$granted',
      );
      debugPrint(
        '[NotificationService] hasPermission: ${granted ? "GRANTED" : "DENIED"} (iOS)',
      );
      return granted;
    }

    final macosPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macosPlugin != null) {
      final permissions = await macosPlugin.checkPermissions();
      final granted = permissions?.isEnabled ?? false;
      debugPrint(
        '[NotificationService] macOS checkPermissions isEnabled=$granted',
      );
      debugPrint(
        '[NotificationService] hasPermission: ${granted ? "GRANTED" : "DENIED"} (macOS)',
      );
      return granted;
    }

    debugPrint(
      '[NotificationService] hasPermission: DENIED (unknown platform)',
    );
    return false;
  }

  Future<void> requestPermissions() async {
    debugPrint('[NotificationService] requestPermissions: start');

    final iosPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[NotificationService] requestPermissions: iOS complete');
      return;
    }

    final macosPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();
    if (macosPlugin != null) {
      await macosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[NotificationService] requestPermissions: macOS complete');
      return;
    }

    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      debugPrint(
        '[NotificationService] requestNotificationsPermission result=$result',
      );
      return;
    }

    debugPrint(
      '[NotificationService] requestPermissions: no platform handler found',
    );
  }

  Future<bool> requestPermissionsIfNeeded() async {
    debugPrint('[NotificationService] requestPermissionsIfNeeded: start');

    if (await hasPermission()) {
      debugPrint(
        '[NotificationService] requestPermissionsIfNeeded: already granted',
      );
      return true;
    }

    debugPrint(
      '[NotificationService] requestPermissionsIfNeeded: requesting...',
    );
    await requestPermissions();
    final granted = await hasPermission();
    debugPrint(
      '[NotificationService] requestPermissionsIfNeeded: final decision=$granted',
    );
    return granted;
  }

  Future<void> _clearCache() async {
    if (!Platform.isAndroid) return;
    try {
      await _androidPermissionChannel
          .invokeMethod('clearScheduledNotificationsCache');
      debugPrint(
          '[NotificationService] Cache cleared successfully via MethodChannel.');
    } catch (e, stackTrace) {
      debugPrint(
          '[NotificationService] Failed to clear cache: $e\n$stackTrace');
    }
  }

  Future<void> _safeCancel(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } on PlatformException catch (e) {
      if (e.message?.contains('Missing type parameter') == true) {
        debugPrint(
            '[NotificationService] Gson TypeToken/R8 error on cancel. Clearing cache...');
        await _clearCache();
        await flutterLocalNotificationsPlugin.cancel(id);
      } else {
        rethrow;
      }
    }
  }

  Future<void> _safeZonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } on PlatformException catch (e) {
      if (e.message?.contains('Missing type parameter') == true) {
        debugPrint(
            '[NotificationService] Gson TypeToken/R8 error on zonedSchedule. Clearing cache...');
        await _clearCache();
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: androidScheduleMode,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _safeCancel(id);
  }

  Future<void> cancelDailyNotifications() async {
    for (final id in NotificationIds.dailyTypes) {
      await cancelNotification(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    for (final id in NotificationIds.all) {
      await cancelNotification(id);
    }
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    try {
      return await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
    } on PlatformException catch (e) {
      if (e.message?.contains('Missing type parameter') == true) {
        debugPrint(
            '[NotificationService] Gson TypeToken/R8 error on pendingNotificationRequests. Clearing cache...');
        await _clearCache();
        return await flutterLocalNotificationsPlugin
            .pendingNotificationRequests();
      } else {
        rethrow;
      }
    }
  }

  static int preferredTimeHour(String preferredTime) {
    switch (preferredTime) {
      case 'Afternoon':
        return 13;
      case 'Evening':
        return 19;
      case 'Morning':
      default:
        return 8;
    }
  }

  NotificationDetails _buildNotificationDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'study_reminder_channel',
        'Study Reminders',
        channelDescription: 'Notifications to remind you to study',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextDailyTime(int hour, [int minute = 0]) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    int minute = 0,
  }) async {
    await cancelNotification(id);
    await _safeZonedSchedule(
      id,
      title,
      body,
      _nextDailyTime(hour, minute),
      _buildNotificationDetails(body),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyReminder({
    required String preferredTime,
    required int incompleteTaskCount,
  }) async {
    final hour = preferredTimeHour(preferredTime);
    final body = incompleteTaskCount > 0
        ? 'Time for your study session! $incompleteTaskCount tasks waiting.'
        : 'Time for your study session! Your plan is ready.';

    await _scheduleDaily(
      id: NotificationIds.dailyReminder,
      title: 'Daily Study Reminder',
      body: body,
      hour: hour,
    );
  }

  Future<void> scheduleStreakAlert() async {
    await _scheduleDaily(
      id: NotificationIds.streakAlert,
      title: 'Streak Alert',
      body: 'Complete a study task today to keep your streak!',
      hour: 20,
    );
  }

  Future<void> scheduleStudyTip() async {
    await _scheduleDaily(
      id: NotificationIds.studyTip,
      title: 'Study Tip',
      body: StudyTips.forDate(DateTime.now()),
      hour: 12,
    );
  }
}
