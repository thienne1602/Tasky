import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Central place to resolve API endpoints depending on runtime.
class ApiConfig {
  const ApiConfig._();

  static const String _envOverride =
      String.fromEnvironment('TASKY_API_BASE'); // allow --dart-define overrides

  static String get _defaultHost {
    if (_envOverride.isNotEmpty) {
      return _envOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:4000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }

    return 'http://127.0.0.1:4000';
  }

  static String get apiBaseUrl => '$_defaultHost/api';

  static Uri apiUri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$apiBaseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  static String resolveFileUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    return '$_defaultHost$relativePath';
  }
}

