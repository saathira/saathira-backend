/// Environment configuration. Override with --dart-define=API_BASE_URL=...
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://saathira-backend.onrender.com/api/v1',
  );
}
