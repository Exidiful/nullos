import 'dart:io';

class ApiConfig {
  static String get anthropicApiKey {
    return Platform.environment['ANTHROPIC_API_KEY'] ?? '';
  }
}
