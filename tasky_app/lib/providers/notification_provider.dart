import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required ApiService api}) : _api = api;

  ApiService _api;
  final List<TaskyNotification> _notifications = [];
  bool _isLoading = false;
  Timer? _pollTimer;

  List<TaskyNotification> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void updateApi(ApiService api) {
    _api = api;
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchNotifications();
    });
    fetchNotifications(); // Initial fetch
  }

  void stopPolling() {
    _pollTimer?.cancel();
  }

  Future<void> fetchNotifications() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final response = await _api.get('/notifications');
      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];

      final newNotifications = data
          .map(
            (item) => TaskyNotification.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      // Check for new unread notifications
      final oldUnreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toSet();

      final newUnreadIds = newNotifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toSet();

      final hasNewNotifications = newUnreadIds
          .difference(oldUnreadIds)
          .isNotEmpty;

      _notifications
        ..clear()
        ..addAll(newNotifications);

      notifyListeners();

      return;
    } catch (error) {
      // Silently fail for polling
    } finally {
      _isLoading = false;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _api.put('/notifications/$notificationId/read');

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (error) {
      // Handle error silently
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.put('/notifications/read-all');

      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      notifyListeners();
    } catch (error) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
