import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

enum ReminderMode {
  chill, // Nhẹ nhàng: 1 lần/ngày
  urgent, // Gấp: 2 lần/ngày
  superUrgent, // Siêu cấp gấp: 3 lần/ngày
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _reminderModeKey = 'reminder_mode';
  static const String _morningReminderTimeKey = 'morning_reminder_time';
  static const String _eveningReminderTimeKey = 'evening_reminder_time';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  // Notification IDs
  static const int _morningReminderId = 1000;
  static const int _eveningReminderId = 1001;
  static const int _deadlineAlertId = 1002;
  static const int _taskCompletedId = 1003;
  static const int _streakReminderId = 1004;
  static const int _motivationalId = 1005;
  static const int _weeklySummaryId = 1006;

  // Task-specific notification IDs (range: 2000-9999)
  static const int _taskNotificationStartId = 2000;

  ReminderMode _currentMode = ReminderMode.chill;
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);
  bool _notificationsEnabled = true;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    await _loadSettings();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'tasky_default_channel',
      'Tasky Notifications',
      description: 'Thông báo từ ứng dụng Tasky',
    );

    const AndroidNotificationChannel morningChannel = AndroidNotificationChannel(
      'morning_reminder',
      'Nhắc nhở buổi sáng',
      description: 'Nhắc nhở bắt đầu ngày với các task',
    );

    const AndroidNotificationChannel eveningChannel = AndroidNotificationChannel(
      'evening_reminder',
      'Nhắc nhở buổi tối',
      description: 'Nhắc nhở cập nhật tiến độ buổi tối',
    );

    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      'task_reminder',
      'Nhắc nhở task',
      description: 'Nhắc nhở về các task cần hoàn thành',
    );

    const AndroidNotificationChannel deadlineChannel = AndroidNotificationChannel(
      'deadline_alert',
      'Cảnh báo deadline',
      description: 'Cảnh báo về deadline sắp đến',
    );

    const AndroidNotificationChannel motivationalChannel = AndroidNotificationChannel(
      'motivational',
      'Lời động viên',
      description: 'Thông điệp động viên và khích lệ',
    );

    const AndroidNotificationChannel weeklyChannel = AndroidNotificationChannel(
      'weekly_summary',
      'Tóm tắt tuần',
      description: 'Tóm tắt thành tích hàng tuần',
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(defaultChannel);
      await androidPlugin.createNotificationChannel(morningChannel);
      await androidPlugin.createNotificationChannel(eveningChannel);
      await androidPlugin.createNotificationChannel(taskChannel);
      await androidPlugin.createNotificationChannel(deadlineChannel);
      await androidPlugin.createNotificationChannel(motivationalChannel);
      await androidPlugin.createNotificationChannel(weeklyChannel);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_reminderModeKey) ?? 0;
    _currentMode = ReminderMode.values[modeIndex];

    final morningTimeStr = prefs.getString(_morningReminderTimeKey) ?? '08:00';
    _morningTime = _parseTimeOfDay(morningTimeStr);

    final eveningTimeStr = prefs.getString(_eveningReminderTimeKey) ?? '20:00';
    _eveningTime = _parseTimeOfDay(eveningTimeStr);

    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderModeKey, _currentMode.index);
    await prefs.setString(_morningReminderTimeKey, _formatTimeOfDay(_morningTime));
    await prefs.setString(_eveningReminderTimeKey, _formatTimeOfDay(_eveningTime));
    await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
  }

  // Settings getters and setters
  ReminderMode get reminderMode => _currentMode;
  TimeOfDay get morningTime => _morningTime;
  TimeOfDay get eveningTime => _eveningTime;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> setReminderMode(ReminderMode mode) async {
    _currentMode = mode;
    await _saveSettings();
    await _rescheduleAllNotifications();
  }

  Future<void> setMorningTime(TimeOfDay time) async {
    _morningTime = time;
    await _saveSettings();
    await _scheduleMorningReminder();
  }

  Future<void> setEveningTime(TimeOfDay time) async {
    _eveningTime = time;
    await _saveSettings();
    await _scheduleEveningReminder();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _saveSettings();
    if (enabled) {
      await _scheduleAllNotifications();
    } else {
      await cancelAllNotifications();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be implemented to navigate to specific screens
    print('Notification tapped: ${response.payload}');
  }

  Future<void> _scheduleAllNotifications() async {
    if (!_notificationsEnabled) return;

    await _scheduleMorningReminder();
    await _scheduleEveningReminder();
    await _scheduleMotivationalNotifications();
    await _scheduleWeeklySummary();
  }

  Future<void> _rescheduleAllNotifications() async {
    await cancelAllNotifications();
    await _scheduleAllNotifications();
  }

  Future<void> _scheduleMorningReminder() async {
    if (!_notificationsEnabled) return;

    await _flutterLocalNotificationsPlugin.cancel(_morningReminderId);

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _morningTime.hour,
      _morningTime.minute,
    );

    // If time has passed today, schedule for tomorrow
    final scheduledDate = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _morningReminderId,
      '🌅 Chào buổi sánggg! ☀️',
      'Hôm nay sẽ là ngày tuyệt vời! Hãy bắt đầu với năng lượng tích cực nhé! 💪✨',
      scheduledDate,
      _getNotificationDetails('morning_reminder'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEveningReminder() async {
    if (!_notificationsEnabled) return;

    await _flutterLocalNotificationsPlugin.cancel(_eveningReminderId);

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _eveningTime.hour,
      _eveningTime.minute,
    );

    // If time has passed today, schedule for tomorrow
    final scheduledDate = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _eveningReminderId,
      '🌙 Buổi tối êm đềm 🛋️',
      'Đừng quên cập nhật tiến độ hôm nay nhé! Bạn đã làm rất tốt rồi! 🌟',
      scheduledDate,
      _getNotificationDetails('evening_reminder'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleMotivationalNotifications() async {
    if (!_notificationsEnabled) return;

    // Random motivational notifications throughout the day
    final messages = [
      '💝 Bạn thật tuyệt vời! Tiếp tục phát huy nhé! ✨',
      '🎯 Mỗi bước chân của bạn đều đáng tự hào! 🌈',
      '⭐ Hãy dành chút thời gian tự thưởng cho bản thân! 🎁',
      '🚀 Bạn có sức mạnh để chinh phục mọi thử thách! 💪',
      '🌟 Hôm nay bạn đã làm được rất nhiều rồi! 🌸',
      '💕 Bạn là người chăm chỉ nhất mà mình biết! 🥰',
      '🎨 Mỗi task hoàn thành là một bức tranh đẹp! 🎭',
      '🌺 Hãy mỉm cười! Bạn đang làm rất tốt! 😊',
      '💫 Bạn như một ngôi sao sáng trên bầu trời! ⭐',
      '🌸 Chúc bạn có ngày thật tuyệt vời! 💐',
    ];

    final random = Random();
    final now = tz.TZDateTime.now(tz.local);

    // Schedule 2-3 random notifications per day based on reminder mode
    final notificationCount = _currentMode == ReminderMode.superUrgent ? 3 :
                             _currentMode == ReminderMode.urgent ? 2 : 1;

    for (int i = 0; i < notificationCount; i++) {
      final hour = 10 + random.nextInt(8); // Between 10 AM and 6 PM
      final minute = random.nextInt(60);
      final message = messages[random.nextInt(messages.length)];

      final scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      final scheduledDate = scheduledTime.isBefore(now)
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _motivationalId + i,
        '💝 Lời động viên nho nhỏ 💕',
        message,
        scheduledDate,
        _getNotificationDetails('motivational'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _scheduleWeeklySummary() async {
    if (!_notificationsEnabled) return;

    await _flutterLocalNotificationsPlugin.cancel(_weeklySummaryId);

    final now = tz.TZDateTime.now(tz.local);
    // Schedule for Sunday evening
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final scheduledTime = tz.TZDateTime(
      tz.local,
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      19, // 7 PM
      0,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _weeklySummaryId,
      '📈 Tuần này của bạn thật tuyệt! ⭐',
      'Hãy xem lại những gì bạn đã đạt được trong tuần qua nhé! Bạn thật tuyệt vời! 🌟',
      scheduledTime,
      _getNotificationDetails('weekly_summary'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  NotificationDetails _getNotificationDetails(String channelKey) {
    // Get importance, priority, vibration pattern and sound based on channel
    Importance importance;
    Priority priority;
    List<int> vibrationPattern;
    String soundFile;

    switch (channelKey) {
      case 'deadline_alert':
        importance = Importance.max;
        priority = Priority.max;
        vibrationPattern = [0, 1000, 200, 1000, 200, 1000];
        soundFile = 'deadline';
        break;
      case 'task_reminder':
        importance = Importance.high;
        priority = Priority.high;
        vibrationPattern = [0, 1000, 500, 1000];
        soundFile = 'task_complete';
        break;
      case 'morning_reminder':
      case 'evening_reminder':
      case 'weekly_summary':
        importance = Importance.high;
        priority = Priority.high;
        vibrationPattern = [0, 1000, 500, 1000];
        soundFile = 'notification';
        break;
      case 'motivational':
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        vibrationPattern = [0, 500, 250, 500];
        soundFile = 'notification';
        break;
      default:
        importance = Importance.high;
        priority = Priority.high;
        vibrationPattern = [0, 1000, 500, 1000];
        soundFile = 'notification';
    }

    final androidDetails = AndroidNotificationDetails(
      channelKey,
      _getChannelName(channelKey),
      channelDescription: _getChannelDescription(channelKey),
      importance: importance,
      priority: priority,
      sound: RawResourceAndroidNotificationSound(soundFile),
      enableVibration: true,
      vibrationPattern: Int64List.fromList(vibrationPattern),
    );

    // iOS sound based on channel
    String iosSoundFile;
    switch (channelKey) {
      case 'deadline_alert':
        iosSoundFile = 'deadline.wav';
        break;
      case 'task_reminder':
        iosSoundFile = 'task_complete.wav';
        break;
      default:
        iosSoundFile = 'notification.wav';
    }

    final iosDetails = DarwinNotificationDetails(
      sound: iosSoundFile,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  String _getChannelName(String channelKey) {
    switch (channelKey) {
      case 'morning_reminder':
        return 'Nhắc nhở buổi sáng';
      case 'evening_reminder':
        return 'Nhắc nhở buổi tối';
      case 'task_reminder':
        return 'Nhắc nhở task';
      case 'deadline_alert':
        return 'Cảnh báo deadline';
      case 'motivational':
        return 'Lời động viên';
      case 'weekly_summary':
        return 'Tóm tắt tuần';
      default:
        return 'Thông báo Tasky';
    }
  }

  String _getChannelDescription(String channelKey) {
    switch (channelKey) {
      case 'morning_reminder':
        return 'Nhắc nhở bắt đầu ngày với các task';
      case 'evening_reminder':
        return 'Nhắc nhở cập nhật tiến độ buổi tối';
      case 'task_reminder':
        return 'Nhắc nhở về các task cần hoàn thành';
      case 'deadline_alert':
        return 'Cảnh báo về deadline sắp đến';
      case 'motivational':
        return 'Thông điệp động viên và khích lệ';
      case 'weekly_summary':
        return 'Tóm tắt thành tích hàng tuần';
      default:
        return 'Thông báo từ ứng dụng Tasky';
    }
  }

  // Task-specific notifications
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_notificationsEnabled) return;

    final taskId = task.id;
    final notificationId = _taskNotificationStartId + taskId;

    // Cancel existing notification for this task
    await _flutterLocalNotificationsPlugin.cancel(notificationId);

    if (task.deadline == null || task.status == 'done') return;

    final now = tz.TZDateTime.now(tz.local);
    final deadline = tz.TZDateTime.from(task.deadline!, tz.local);

    if (deadline.isBefore(now)) return; // Deadline has passed

    final hoursUntilDeadline = deadline.difference(now).inHours;

    // Schedule based on reminder mode
    int reminderHours;
    switch (_currentMode) {
      case ReminderMode.chill:
        reminderHours = 24; // 1 day before
        break;
      case ReminderMode.urgent:
        reminderHours = 12; // 12 hours before
        break;
      case ReminderMode.superUrgent:
        reminderHours = 6; // 6 hours before
        break;
    }

    if (hoursUntilDeadline <= reminderHours) {
      final reminderTime = deadline.subtract(Duration(hours: reminderHours));

      if (reminderTime.isAfter(now)) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '⏰ Nhắc nhở task',
          'Task "${task.title}" sắp đến deadline!',
          reminderTime,
          _getNotificationDetails('task_reminder'),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> showTaskCompletedNotification(Task task) async {
    if (!_notificationsEnabled) return;

    // Random celebration messages
    final celebrationMessages = [
      'Bạn đã hoàn thành xuất sắc! 🎊✨',
      'Yeeey! Một task nữa đã xong! 🎉🎈',
      'Bạn thật tuyệt vời! Chúc mừng nhé! 🏆💫',
      'Wow! Bạn làm được rồi! 🎊🌟',
      'Chúc mừng siêu sao của chúng ta! ⭐🎉',
    ];

    final random = Random();
    final message = celebrationMessages[random.nextInt(celebrationMessages.length)];

    await _flutterLocalNotificationsPlugin.show(
      _taskCompletedId,
      '🎉 Yeeey! Bạn làm được rồi! 🎊',
      message,
      _getNotificationDetails('task_reminder'),
    );
  }

  Future<void> showDeadlineAlert(Task task) async {
    if (!_notificationsEnabled) return;

    final timeLeft = task.deadline!.difference(DateTime.now());
    final hoursLeft = timeLeft.inHours;
    final minutesLeft = timeLeft.inMinutes % 60;

    String timeMessage;
    if (hoursLeft > 0) {
      timeMessage = '$hoursLeft giờ $minutesLeft phút nữa';
    } else {
      timeMessage = '$minutesLeft phút nữa';
    }

    // Friendly deadline messages
    final deadlineMessages = [
      'Nhắc nhở nhẹ nhàng: Task "${task.title}" còn $timeMessage thôi! 💪',
      'Bạn vẫn còn thời gian! Task "${task.title}" deadline trong $timeMessage! ⏰',
      'Đừng lo! Bạn vẫn có $timeMessage để hoàn thành "${task.title}"! 🌟',
      'Nhắc nhỏ: "${task.title}" sẽ đến deadline trong $timeMessage! 💕',
    ];

    final random = Random();
    final message = deadlineMessages[random.nextInt(deadlineMessages.length)];

    await _flutterLocalNotificationsPlugin.show(
      _deadlineAlertId,
      '⏰ Nhắc nhở nhẹ nhàng! 🔔',
      message,
      _getNotificationDetails('deadline_alert'),
    );
  }

  Future<void> showStreakReminder(int streakDays) async {
    if (!_notificationsEnabled) return;

    final streakMessages = [
      'Wow! Bạn đã duy trì $streakDays ngày liên tiếp! Bạn thật tuyệt vời! 🔥⭐',
      '$streakDays ngày liên tiếp! Bạn như siêu nhân vậy! 🦸‍♀️💪',
      'Chuỗi $streakDays ngày hoàn hảo! Bạn thật đáng tự hào! 🌟🏆',
      'Bạn đã duy trì streak $streakDays ngày! Tiếp tục nhé! 🚀✨',
      '$streakDays ngày liên tiếp! Bạn là huyền thoại rồi! 🏅🎉',
    ];

    final random = Random();
    final message = streakMessages[random.nextInt(streakMessages.length)];

    await _flutterLocalNotificationsPlugin.show(
      _streakReminderId,
      '🔥 Siêu nhân chăm chỉ! 🦸‍♀️',
      message,
      _getNotificationDetails('motivational'),
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    final notificationId = _taskNotificationStartId + taskId;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Request permissions
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    required String channelKey,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title,
      body,
      _getNotificationDetails(channelKey),
    );
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final iosPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = false;

    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    }

    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }
}
