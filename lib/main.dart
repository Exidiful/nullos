import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:null_os/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<String> _loadApiKey() async {
    // Using hardcoded API key from api_config.dart
    return ApiConfig.anthropicApiKey;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadApiKey(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return MaterialApp(
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return ChangeNotifierProvider(
          create: (_) => ChatProvider(apiKey: snapshot.data!),
          child: ShadApp.material(
            title: 'NullOS Chat',
            materialThemeBuilder: (context, theme) => theme.copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6750A4),
                brightness: Brightness.dark,
              ).copyWith(
                secondary: const Color(0xFF9377FF),
                surface: const Color(0xFF1C1B1F),
                background: const Color(0xFF141218),
              ),
              scaffoldBackgroundColor: const Color(0xFF141218),
            ),
            home: ChatScreen(),
          ),
        );
      },
    );
  }
}
