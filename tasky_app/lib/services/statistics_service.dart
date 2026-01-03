import '../models/statistics.dart';
import 'api_service.dart';

class StatisticsService {
  final ApiService _api;

  StatisticsService(this._api);

  // Test method to check API connectivity
  Future<Map<String, dynamic>> testConnection() async {
    try {
      return await _api.get('/statistics/debug');
    } catch (error) {
      print('API test failed: $error');
      throw error;
    }
  }

  Future<TaskStatistics> getStatistics() async {
    try {
      print('🔍 Fetching statistics from API...');
      final data = await _api.get('/statistics');
      print('✅ Statistics API response: ${data['success']}');
      return TaskStatistics.fromJson(data['data']);
    } catch (error) {
      print('❌ Error fetching statistics: $error');
      throw Exception('Error fetching statistics: $error');
    }
  }

  Future<TaskStatistics> getTeamStatistics(int teamId) async {
    try {
      final data = await _api.get('/statistics/teams/$teamId');
      return TaskStatistics.fromJson(data['data']);
    } catch (error) {
      throw Exception('Error fetching team statistics: $error');
    }
  }

  Future<TaskStatistics> getUserStatistics(int userId) async {
    try {
      final data = await _api.get('/statistics/users/$userId');
      return TaskStatistics.fromJson(data['data']);
    } catch (error) {
      throw Exception('Error fetching user statistics: $error');
    }
  }
}
