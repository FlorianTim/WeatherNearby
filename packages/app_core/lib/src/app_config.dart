import 'app_flavor.dart';

class AppConfig {
  AppConfig({required this.flavor, required this.apiBaseUrl});

  final AppFlavor flavor;
  final String apiBaseUrl;

  factory AppConfig.fromEnvironment() {
    final apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );

    return AppConfig(flavor: AppFlavor.current, apiBaseUrl: apiBaseUrl);
  }
}
