import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Raised for any failure talking to the backend — bad credentials,
/// validation errors, unauthorized requests, or the backend being
/// unreachable. [message] is always safe to show directly to the user.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class User {
  final int id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] as int, email: json['email'] as String);
  }
}

/// Single, centralized client for every backend call. Screens should never
/// call `http` directly — they go through here so the base URL, headers,
/// and error handling stay in one place.
class ApiClient {
  ApiClient._();

  static Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  static Future<T> _guarded<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    } on HttpException {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    } on FormatException {
      throw ApiException('Received an unexpected response from the server.');
    } on http.ClientException {
      throw ApiException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        final detail = body['detail'];
        if (detail is String) return detail;
        return detail.toString();
      }
    } catch (_) {
      // Fall through to a generic message below.
    }
    return 'Something went wrong. Please try again.';
  }

  /// POST /signup — throws [ApiException] with a user-facing message on failure.
  static Future<void> signup({
    required String email,
    required String password,
  }) {
    return _guarded(() async {
      final response = await http.post(
        _uri('/signup'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 201) {
        throw ApiException(
          _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }
    });
  }

  /// POST /login — returns the JWT access token, or throws [ApiException].
  static Future<String> login({
    required String email,
    required String password,
  }) {
    return _guarded(() async {
      final response = await http.post(
        _uri('/login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode == 401
              ? 'Incorrect email or password.'
              : _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['access_token'] as String;
    });
  }

  /// GET /me — attaches [token] as a Bearer token. Throws [ApiException]
  /// (statusCode 401) if the token is missing/invalid/expired.
  static Future<User> getMe(String token) {
    return _guarded(() async {
      final response = await http.get(
        _uri('/me'),
        headers: {..._jsonHeaders, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode == 401
              ? 'Your session has expired. Please log in again.'
              : _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }

      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    });
  }
}
