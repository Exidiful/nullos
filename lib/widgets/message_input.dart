import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:null_os/models/message.dart';
import 'package:null_os/utils/error_handler.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _messageType = 'chat';

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isLoading) return;
    
    setState(() => _isLoading = true);
    _controller.clear();

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(message, MessageRole.user);
    
    try {
      await chatProvider.streamResponse(message);
    } catch (e) {
      if (mounted) {
        final errorMessage = ErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _sendMessage,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          ),
        ),
      ),
      child: Column(
        children: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: LinearProgressIndicator(
                value: _uploadProgress,
              ),
            ),
          Row(
            children: [
              PopupMenuButton<String>(
                initialValue: _messageType,
                onSelected: (value) {
                  setState(() {
                    _messageType = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'chat',
                    child: Text('Chat'),
                  ),
                  const PopupMenuItem(
                    value: 'system',
                    child: Text('System'),
                  ),
                  const PopupMenuItem(
                    value: 'prompt',
                    child: Text('Prompt'),
                  ),
                ],
                child: Row(
                  children: [
                    Text(_messageType.toUpperCase()),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: 'Type your message here',
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message (markdown supported)...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => !_isLoading ? _sendMessage() : null,
                    enabled: !_isLoading,
                    maxLines: 6,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 2000,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Send message',
                child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
