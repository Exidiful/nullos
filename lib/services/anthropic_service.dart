import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/error_handler.dart';

class AnthropicService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-3-opus-20240229';
  
  final String apiKey;
  final http.Client _client = http.Client();

  AnthropicService({required this.apiKey}) {
    print('Debug: Checking API key configuration...');
    print('Debug: API key value: $apiKey');
    
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    
    if (!apiKey.startsWith('sk-ant-')) {
      throw ArgumentError('Invalid API key format. Anthropic API keys should start with "sk-ant-"');
    }
    
    print('Debug: API key validation passed');
    print('Debug: API key length: ${apiKey.length}');
    print('Debug: API key prefix: ${apiKey.substring(0, 7)}...');
  }

  Future<Stream<String>> streamChat(String message) async {
    if (message.isEmpty) {
      throw ArgumentError('Message must not be empty');
    }
    http.Response? response;
    try {
      response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [{'role': 'user', 'content': message}],
          'stream': true,
          'max_tokens': 4096,
        }),
      );

      if (response.statusCode != 200) {
        print('API Response Status Code: ${response.statusCode}');
        print('API Response Headers: ${response.headers}');
        print('API Response Body: ${response.body}');
        throw NetworkError(
          message: 'Failed to get response from Anthropic (Status: ${response.statusCode})\nResponse: ${response.body}',
          statusCode: response.statusCode,
        );
      }

      return Stream.fromIterable(
        response.body
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map<String>((line) {
          if (line.startsWith('data: ')) {
            final data = jsonDecode(line.substring(6));
            if (data['type'] == 'content_block_delta') {
              return data['delta']['text'] ?? '';
            }
          }
          return '';
        }).where((text) => text.isNotEmpty),
      );
      
    } catch (e, stackTrace) {
      print('AnthropicService Error: $e');
      print('Stack trace: $stackTrace');
      throw NetworkError(
        message: 'Failed to connect to Anthropic API: $e',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
