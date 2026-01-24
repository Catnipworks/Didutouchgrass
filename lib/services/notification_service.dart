import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const String _enabledKey = 'notifications_enabled';
  static const String _timeKey = 'reminder_time';
  static const String _frequencyKey = 'reminder_frequency';
  static const int _notificationId = 1;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback function for when notification is tapped
  static Function? onNotificationTapped;

  // Initialize notifications (call this in main.dart or app startup)
  static Future<void> initialize() async {
    // DON'T initialize timezones here - it's done in main.dart
    
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
        
        // Call the callback if it was registered
        if (response.payload == 'random_activity' &&
            onNotificationTapped != null) {
          onNotificationTapped!();
        }
      },
    );

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  // Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  // Get reminder time
  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_timeKey) ?? '14:00';
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Set reminder time
  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString(_timeKey, timeString);
  }

  // Get frequency setting
  Future<String> getFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_frequencyKey) ?? 'once_daily';
  }

  // Set frequency setting
  Future<void> setFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_frequencyKey, frequency);
  }

  // Schedule reminder notification
  Future<void> scheduleReminder(TimeOfDay time, String frequency) async {
    await cancelReminder(); // Cancel any existing reminders first

    final now = tz.TZDateTime.now(tz.local);
    print('🔔 Current time: $now');
    
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('🔔 Time already passed, scheduling for tomorrow');
    }

    print('🔔 Will notify at: $scheduledDate');
    print('🔔 Frequency: $frequency');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'grass_channel',
          'Grass Reminders',
          channelDescription: 'Reminders to touch grass',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Schedule based on frequency
    if (frequency == 'once_daily') {
      // Schedule for every day at the same time
      await _notificationsPlugin.zonedSchedule(
        _notificationId,
        'did u touch grass?',
        'tap to pick an activity',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'random_activity',
      );
      print('✅ Notification scheduled successfully!');
    } else if (frequency == 'weekdays') {
      // Schedule for weekdays only (Monday-Friday)
      for (int i = 0; i < 7; i++) {
        final nextDate = scheduledDate.add(Duration(days: i));
        // 1 = Monday, 5 = Friday
        if (nextDate.weekday >= 1 && nextDate.weekday <= 5) {
          await _notificationsPlugin.zonedSchedule(
            _notificationId + i,
            'did u touch grass?',
            'tap to pick an activity',
            nextDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'random_activity',
          );
        }
      }
      print('✅ Weekday notifications scheduled successfully!');
    } else if (frequency == 'random') {
      // Schedule 5 random times throughout the day between 9 AM and 9 PM
      final random = math.Random();
      for (int i = 0; i < 5; i++) {
        final randomHour = 9 + random.nextInt(12); // 9 AM to 9 PM
        final randomMinute = random.nextInt(60);

        final randomDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          randomHour,
          randomMinute,
        );

        await _notificationsPlugin.zonedSchedule(
          _notificationId + i,
          'did u touch grass?',
          'tap to pick an activity',
          randomDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'random_activity',
        );
      }
      print('✅ Random notifications scheduled successfully!');
    }

    print(
      'Scheduled reminder at ${time.hour}:${time.minute} with frequency: $frequency',
    );
  }

  // Cancel reminder notification
  Future<void> cancelReminder() async {
    await _notificationsPlugin.cancelAll();
    print('All reminders cancelled');
  }

  // Get a random activity index (used when notification is tapped)
  int getRandomActivityIndex(int totalActivities) {
    final random = math.Random();
    return random.nextInt(totalActivities);
  }
}