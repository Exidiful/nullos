import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:null_os/widgets/custom_code_block_builder.dart';
import 'package:null_os/widgets/media_content.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';

class ChatMessage extends StatelessWidget {
  final Message message;

  const ChatMessage({
    super.key,
    required this.message,
  });

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment:
              message.role == MessageRole.user ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.copy),
                        title: const Text('Copy message'),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.content));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message copied to clipboard'),
                            ),
                          );
                        },
                      ),
                      if (!_isUser)
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: const Text('Regenerate response'),
                          onTap: () {
                            // TODO: Implement regenerate
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                );
              },
              child: ShadCard(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    minWidth: 0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.content.length > 500)
                        ExpansionTile(
                          title: const Text('Show full message'),
                          children: [_buildMessageContent(context)],
                        )
                      else
                        _buildMessageContent(context),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.status == MessageStatus.typing)
                            const ShadBadge(
                              child: Text('Typing...'),
                            )
                          else if (message.status == MessageStatus.error)
                            Tooltip(
                              message: message.errorMessage ?? 'Error sending message',
                              child: Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            )
                          else
                            Text(
                              DateFormat('HH:mm').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          if (message.status == MessageStatus.error)
                            TextButton(
                              onPressed: () {
                                Provider.of<ChatProvider>(context, listen: false)
                                    .retryMessage(message.id);
                              },
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_containsMediaUrl(message.content))
          MediaContent(url: _extractMediaUrl(message.content)),
        MarkdownBody(
          data: _stripMediaUrl(message.content),
          builders: {
            'code': CustomCodeBlockBuilder(context),
          },
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            code: TextStyle(
              backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              color: Theme.of(context).colorScheme.primary,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  bool _containsMediaUrl(String content) {
    final mediaPattern = RegExp(r'\bhttps?:\/\/\S+\.(png|jpg|jpeg|gif|mp4)\b', caseSensitive: false);
    return mediaPattern.hasMatch(content);
  }

  String _extractMediaUrl(String content) {
    final mediaPattern = RegExp(r'\bhttps?:\/\/\S+\.(png|jpg|jpeg|gif|mp4)\b', caseSensitive: false);
    final match = mediaPattern.firstMatch(content);
    return match?.group(0) ?? '';
  }

  String _stripMediaUrl(String content) {
    return content.replaceAll(RegExp(r'\bhttps?:\/\/\S+\.(png|jpg|jpeg|gif|mp4)\b', caseSensitive: false), '');
  }
}
