import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps secure, encrypted storage for the JWT access token.
/// Never use SharedPreferences for this — tokens must not sit in plain storage.
class AuthStorage {
  AuthStorage._();

  static const _tokenKey = 'access_token';

  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
