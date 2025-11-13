import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required SharedPreferences prefs, ApiService? apiService})
      : _prefs = prefs,
        _apiService = apiService ?? ApiService();

  static const _tokenKey = 'tasky_token';
  static const _userKey = 'tasky_user';

  final SharedPreferences _prefs;
  final ApiService _apiService;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  ApiService get api => _apiService;

  Future<void> initialize() async {
    final storedToken = _prefs.getString(_tokenKey);
    final storedUserJson = _prefs.getString(_userKey);
    if (storedToken != null && storedUserJson != null) {
      try {
        _token = storedToken;
        _apiService.updateToken(_token);
        _currentUser = User.fromJson(
          jsonDecode(storedUserJson) as Map<String, dynamic>,
        );
        notifyListeners();
      } catch (_) {
        await logout();
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final response = await _apiService.post(
        '/auth/login',
        body: {'email': email, 'password': password},
        withAuth: false,
      );

      await _cacheSession(response);
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? username,
  }) async {
    _setLoading(true);
    try {
      final body = {
        'name': name,
        'email': email,
        'password': password,
      };
      if (username != null && username.isNotEmpty) {
        body['username'] = username;
      }

      final response = await _apiService.post(
        '/auth/register',
        body: body,
        withAuth: false,
      );

      await _cacheSession(response);
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    try {
      final response = await _apiService.get('/auth/me');
      _currentUser = User.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
      await _prefs.setString(_userKey, jsonEncode(response['data']));
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
    }
  }

  Future<void> updateProfile({required String name, String? avatar}) async {
    if (!isAuthenticated) return;
    try {
      await _apiService.put(
        '/users/me',
        body: {'name': name, 'avatar': avatar},
      );
      _currentUser = _currentUser?.copyWith(name: name, avatar: avatar);
      await _prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      notifyListeners();
    } catch (error) {
      _setError(error.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!isAuthenticated) return;
    try {
      _setLoading(true);
      await _apiService.put(
        '/users/me/password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      _error = null;
    } catch (error) {
      _setError(error.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _apiService.updateToken(null);
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> _cacheSession(Map<String, dynamic> response) async {
    final token = response['token']?.toString();
    final data = Map<String, dynamic>.from(response['data'] as Map);
    if (token == null) throw Exception('Missing token');

    _token = token;
    _currentUser = User.fromJson(data);
    _apiService.updateToken(_token);

    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(data));
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }
}
