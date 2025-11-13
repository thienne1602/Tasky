import 'package:flutter/material.dart';

import '../models/team.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class TeamProvider extends ChangeNotifier {
  TeamProvider({required ApiService api}) : _api = api;

  ApiService _api;
  final List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  List<Team> get teams => List.unmodifiable(_teams);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeams() async {
    _setLoading(true);
    try {
      final response = await _api.get('/teams');
      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
      _teams
        ..clear()
        ..addAll(
          data.map((item) => Team.fromJson(item as Map<String, dynamic>)),
        );
      _error = null;
    } catch (error) {
      _error = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTeam({required String name, String? description}) async {
    try {
      await _api.post(
        '/teams',
        body: {'name': name, 'description': description},
      );
      await fetchTeams();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> inviteMember({
    required int teamId,
    required String email,
  }) async {
    await _api.post('/teams/$teamId/members', body: {'email': email});
  }

  Future<void> addMember({
    required int teamId,
    required String email,
  }) async {
    await _api.post('/teams/$teamId/members', body: {'email': email});
    await fetchTeams();
  }

  Future<Team> fetchTeamDetail(int teamId) async {
    final response = await _api.get('/teams/$teamId');
    return Team.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<User>> fetchMembers() async {
    final response = await _api.get('/users');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> transferLeadership({
    required int teamId,
    required int newLeaderId,
  }) async {
    await _api.post(
      '/teams/$teamId/transfer-leadership',
      body: {'newLeaderId': newLeaderId},
    );
    await fetchTeams();
  }

  Future<void> updateTeam({
    required int teamId,
    required String name,
    String? description,
  }) async {
    await _api.put(
      '/teams/$teamId',
      body: {'name': name, 'description': description},
    );
    await fetchTeams();
  }

  Future<void> deleteTeam(int teamId) async {
    await _api.delete('/teams/$teamId');
    await fetchTeams();
  }

  Future<void> removeMember({
    required int teamId,
    required int userId,
  }) async {
    await _api.delete(
      '/teams/$teamId/members',
      body: {'userId': userId},
    );
    await fetchTeams();
  }

  Future<void> leaveTeam(int teamId) async {
    await _api.post('/teams/$teamId/leave');
    await fetchTeams();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void updateApi(ApiService api) {
    _api = api;
  }
}
