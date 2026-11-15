import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _envApiUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
