import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_message.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});
  
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) => ChatProvider(apiKey: ApiConfig.anthropicApiKey),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Text(
                        'NullOS Chat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Clear chat history',
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear Chat'),
                                content: const Text('Are you sure you want to clear all messages? This cannot be undone.'),
                                actions: [
                                  ShadButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ShadButton(
                                    onPressed: () {
                                      Provider.of<ChatProvider>(context, listen: false).clearChat();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Exit application',
                        child: IconButton(
                          icon: const Icon(Icons.exit_to_app),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Exit Application'),
                                content: const Text('Are you sure you want to exit?'),
                                actions: [
                                  ShadButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ShadButton(
                                    onPressed: () => SystemNavigator.pop(),
                                    child: const Text('Exit'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.settings),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'theme',
                            child: Row(
                              children: const [
                                Icon(Icons.palette_outlined),
                                SizedBox(width: 8),
                                Text('Theme'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: const [
                                Icon(Icons.settings_outlined),
                                SizedBox(width: 8),
                                Text('Settings'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'about',
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Text('About'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'theme':
                              // TODO: Implement theme switching
                              break;
                            case 'settings':
                              // TODO: Implement settings
                              break;
                            case 'about':
                              // TODO: Show about dialog
                              break;
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                    ),
                    child: Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          physics: const AlwaysScrollableScrollPhysics(),
                          reverse: true,
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[chatProvider.messages.length - 1 - index];
                            return Column(
                              children: [
                                ChatMessage(message: message),
                                if (index < chatProvider.messages.length - 1)
                                  const Divider(),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                      ),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: const MessageInput(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
