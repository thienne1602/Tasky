import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/comment.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({required ApiService api}) : _api = api;

  ApiService _api;
  final List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDay = DateTime.now();

  List<Task> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDay => _selectedDay;
  int get totalTasks => _tasks.length;
  int get completedTasks =>
      _tasks.where((task) => task.status == 'done').length;

  List<Task> get tasksForSelectedDay => _tasks
      .where(
        (task) =>
            task.deadline != null && _isSameDay(task.deadline!, _selectedDay),
      )
      .toList()
    ..sort(
      (a, b) => (a.deadline ?? DateTime.now()).compareTo(
        b.deadline ?? DateTime.now(),
      ),
    );

  List<Task> get upcomingDeadlines => _tasks
      .where(
        (task) =>
            task.deadline != null && task.deadline!.isAfter(DateTime.now()),
      )
      .toList()
    ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

  List<Task> myTasks(int userId) =>
      _tasks.where((task) => task.assignedTo == userId).toList()
        ..sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });

  List<Task> createdByMe(int userId) =>
      _tasks.where((task) => task.createdBy == userId).toList()
        ..sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });

  void updateApi(ApiService api) {
    _api = api;
  }

  Future<void> fetchTasks() async {
    _setLoading(true);
    try {
      final response = await _api.get('/tasks');
      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
      _tasks
        ..clear()
        ..addAll(
          data.map((item) => Task.fromJson(item as Map<String, dynamic>)),
        );
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTask({
    required String title,
    String? description,
    DateTime? deadline,
    String status = 'todo',
    required int teamId,
    int? assigneeId,
  }) async {
    try {
      await _api.post(
        '/tasks',
        body: {
          'title': title,
          'description': description,
          'deadline': deadline?.toIso8601String(),
          'status': status,
          'team_id': teamId,
          'assigned_to': assigneeId,
        },
      );
      await fetchTasks();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _api.put(
        '/tasks/${task.id}',
        body: {
          'title': task.title,
          'description': task.description,
          'deadline': task.deadline?.toIso8601String(),
          'status': task.status,
          'assigned_to': task.assignedTo,
        },
      );
      await fetchTasks();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    try {
      await _api.put(
        '/tasks/$taskId',
        body: {
          'status': status,
        },
      );
      await fetchTasks();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _api.delete('/tasks/$id');
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> sendTaskReminder(int taskId) async {
    try {
      await _api.post('/tasks/$taskId/remind');
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Comment>> fetchComments(int taskId) async {
    final response = await _api.get('/tasks/$taskId');
    final data = response['data'] as Map<String, dynamic>;
    return (data['comments'] as List<dynamic>)
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> addComment({
    required int taskId,
    required String content,
  }) async {
    final response = await _api.post(
      '/tasks/$taskId/comments',
      body: {'content': content},
    );
    final comment = Comment.fromJson(response['data'] as Map<String, dynamic>);
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final updatedComments = [..._tasks[index].comments, comment];
      _tasks[index] = _tasks[index].copyWith(comments: updatedComments);
      notifyListeners();
    }
    return comment;
  }

  Future<void> removeComment({
    required int taskId,
    required int commentId,
  }) async {
    await _api.delete('/tasks/$taskId/comments/$commentId');
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      final updatedComments = _tasks[index]
          .comments
          .where((comment) => comment.id != commentId)
          .toList();
      _tasks[index] = _tasks[index].copyWith(comments: updatedComments);
      notifyListeners();
    }
  }

  Future<Task> fetchTaskDetail(int taskId) async {
    final response = await _api.get('/tasks/$taskId');
    final task = Task.fromJson(response['data'] as Map<String, dynamic>);
    final index = _tasks.indexWhere((item) => item.id == taskId);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
    return task;
  }

  void selectDay(DateTime day) {
    _selectedDay = DateTime(day.year, day.month, day.day);
    notifyListeners();
  }

  String deadlineLabel(Task task) {
    if (task.deadline == null) return 'Không deadline';
    return DateFormat('dd MMM, HH:mm', 'vi').format(task.deadline!.toLocal());
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
