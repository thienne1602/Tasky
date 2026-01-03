import 'dart:async';
import '../models/task.dart';
import 'audio_service.dart';
import 'notification_service.dart';

class DeadlineAlertService {
  static final DeadlineAlertService _instance = DeadlineAlertService._internal();
  factory DeadlineAlertService() => _instance;
  DeadlineAlertService._internal();

  Timer? _alertTimer;
  final Set<int> _alertedTaskIds = {}; // Track tasks already alerted
  final Duration _checkInterval = const Duration(minutes: 5); // Check every 5 minutes
  final NotificationService _notificationService = NotificationService();

  void startMonitoring(List<Task> tasks) {
    stopMonitoring();

    _alertTimer = Timer.periodic(_checkInterval, (_) {
      _checkDeadlines(tasks);
    });

    // Initial check
    _checkDeadlines(tasks);
  }

  void stopMonitoring() {
    _alertTimer?.cancel();
    _alertTimer = null;
  }

  void _checkDeadlines(List<Task> tasks) {
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.status == 'done' || task.deadline == null) continue;

      final timeLeft = task.deadline!.difference(now);

      // Alert conditions: overdue or less than 24 hours left
      final shouldAlert = timeLeft.isNegative || timeLeft.inHours < 24;

      // Only alert if we haven't alerted for this task before
      if (shouldAlert && !_alertedTaskIds.contains(task.id)) {
        AudioService().playDeadlineAlertSound();
        _notificationService.showDeadlineAlert(task);
        _alertedTaskIds.add(task.id);
      }

      // Clear alert status if deadline is no longer urgent
      if (!shouldAlert && _alertedTaskIds.contains(task.id)) {
        _alertedTaskIds.remove(task.id);
      }
    }
  }

  void resetAlertForTask(int taskId) {
    _alertedTaskIds.remove(taskId);
  }

  void dispose() {
    stopMonitoring();
    _alertedTaskIds.clear();
  }
}
