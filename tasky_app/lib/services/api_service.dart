import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'http://127.0.0.1:4000/api';

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  void updateToken(String? token) {
    _token = token;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$_baseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _client.get(
      _buildUri(path, query),
      headers: _headers(),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.put(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.delete(
      _buildUri(path),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    final Map<String, dynamic> payload =
        jsonDecode(response.body.isEmpty ? '{}' : response.body)
            as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }
    final message = payload['message']?.toString() ?? 'Unexpected error';
    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      details: payload['errors'],
    );
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.details});

  final int statusCode;
  final String message;
  final dynamic details;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
