/// Centralized backend configuration.
///
/// Override at build/run time without touching code, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///   flutter build web --dart-define=API_BASE_URL=https://api.cybersaathi.example
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
