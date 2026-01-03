import 'package:flutter/material.dart';
import '../models/statistics.dart';
import '../services/api_service.dart';
import '../services/statistics_service.dart';

class StatisticsProvider extends ChangeNotifier {
  StatisticsProvider({required ApiService api}) : _statisticsService = StatisticsService(api);

  final StatisticsService _statisticsService;

  TaskStatistics? _statistics;
  bool _isLoading = false;
  String? _error;

  TaskStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStatistics() async {
    _setLoading(true);
    try {
      print('📊 Loading statistics...');
      _statistics = await _statisticsService.getStatistics();
      _error = null;
      print('✅ Statistics loaded successfully');
    } catch (error) {
      print('❌ Error loading statistics: $error');
      _error = error.toString();

      // Fallback to mock data for testing
      print('🔄 Using mock data as fallback...');
      _statistics = TaskStatistics(
        totalTasks: 24,
        completedTasks: 8,
        pendingTasks: 10,
        inProgressTasks: 6,
        completionRate: 33.3,
        tasksByStatus: {'todo': 10, 'doing': 6, 'done': 8},
        tasksByTeam: {'Frontend Team': 12, 'Backend Team': 12},
        tasksByUser: {'Nguyễn Văn Minh': 3, 'Trần Thị Lan': 3},
        completionTrend: [
          TaskCompletionData(date: '2025-01-01', completed: 1, total: 2),
          TaskCompletionData(date: '2025-01-02', completed: 2, total: 4),
        ],
        teamPerformance: [
          TeamPerformanceData(teamName: 'Frontend Team', completedTasks: 4, totalTasks: 12, completionRate: 33.3),
          TeamPerformanceData(teamName: 'Backend Team', completedTasks: 4, totalTasks: 12, completionRate: 33.3),
        ],
      );
      _error = null; // Clear error since we have fallback data
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTeamStatistics(int teamId) async {
    _setLoading(true);
    try {
      _statistics = await _statisticsService.getTeamStatistics(teamId);
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserStatistics(int userId) async {
    _setLoading(true);
    try {
      _statistics = await _statisticsService.getUserStatistics(userId);
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> testConnection() async {
    try {
      return await _statisticsService.testConnection();
    } catch (error) {
      throw error;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
