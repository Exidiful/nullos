import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../models/message.dart';
import '../utils/error_handler.dart';
import '../services/anthropic_service.dart';

class ChatProvider with ChangeNotifier {
  final AnthropicService _anthropicService;
  final List<Message> _messages = [];

  ChatProvider({required String apiKey}) 
    : _anthropicService = AnthropicService(apiKey: apiKey);
  List<Message> get messages => List.unmodifiable(_messages);
  
  Message? get lastMessage => 
      _messages.isNotEmpty ? _messages.last : null;

  void addMessage(String content, MessageRole role, {
    MessageStatus status = MessageStatus.sent,
    VoidCallback? onComplete,
  }) {
    _messages.add(Message(
      content: content,
      role: role,
      status: status,
    ));
    notifyListeners();
    onComplete?.call();
  }

  void updateMessage(String id, {
    String? content,
    MessageRole? role,
    MessageStatus? status,
    String? errorMessage,
  }) {
    final index = _messages.indexWhere((msg) => msg.id == id);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        content: content,
        role: role,
        status: status,
        errorMessage: errorMessage,
      );
      notifyListeners();
    }
  }

  void setTyping(bool isTyping) {
    if (isTyping) {
      addMessage('', MessageRole.assistant, status: MessageStatus.typing);
    } else {
      _messages.removeWhere(
          (msg) => msg.status == MessageStatus.typing);
      notifyListeners();
    }
  }

  Future<void> streamResponse(String userMessage) async {
    final message = Message(
      content: '',
      role: MessageRole.assistant,
      status: MessageStatus.typing
    );
    _messages.add(message);
    notifyListeners();

    try {
      final stream = await _anthropicService.streamChat(userMessage);
      String fullResponse = '';
      
      await for (final chunk in stream) {
        fullResponse += chunk;
        updateMessage(message.id, content: fullResponse);
      }
      
      updateMessage(message.id, status: MessageStatus.sent);
      await saveMessages();
      
    } catch (e, stackTrace) {
      final errorMsg = ErrorHandler.getErrorMessage(e);
      developer.log(
        'Stream response error',
        error: e,
        stackTrace: stackTrace,
        name: 'ChatProvider',
        time: DateTime.now(),
      );
      
      // Log the last few messages for context
      developer.log(
        'Recent message context',
        name: 'ChatProvider',
        error: _messages.length >= 3 
          ? _messages.sublist(_messages.length - 3).toString()
          : _messages.toString(),
      );
      
      updateMessage(
        message.id,
        status: MessageStatus.error,
        errorMessage: errorMsg,
      );
      
      if (e is NetworkError) {
        throw ChatError(
          'Connection failed: ${e.message}',
          code: 'NETWORK_ERROR',
          originalError: e,
          stackTrace: stackTrace,
        );
      } else {
        throw ChatError(
          'Failed to get response: $errorMsg',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  void dispose() {
    _anthropicService.dispose();
    super.dispose();
  }

  Future<void> saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = jsonEncode(_messages.map((m) => m.toJson()).toList());
      
      if (!await prefs.setString('chat_messages', messagesJson)) {
        throw StorageError('Failed to save messages to storage');
      }
    } catch (e) {
      throw StorageError(
        'Failed to save messages',
        originalError: e,
      );
    }
  }

  Future<void> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages');
      
      if (messagesJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(messagesJson);
          _messages.clear();
          _messages.addAll(
            decoded.map((m) => Message.fromJson(m as Map<String, dynamic>))
          );
          notifyListeners();
        } catch (e) {
          throw StorageError(
            'Failed to parse saved messages',
            originalError: e,
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Failed to load messages',
        error: e,
        stackTrace: stackTrace,
        name: 'ChatProvider',
      );
      
      if (e is StorageError) rethrow;
      throw StorageError(
        'Failed to load messages',
        originalError: e,
      );
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
    saveMessages();
  }

  void addSystemMessage(String content) {
    addMessage(content, MessageRole.system);
  }

  Future<void> retryMessage(String messageId) async {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) {
      throw ValidationError('Message not found', field: 'messageId');
    }

    final maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        updateMessage(messageId, status: MessageStatus.sending);
        
        // Get the last user message before this assistant message
        final userMessageIndex = _messages
            .sublist(0, index)
            .lastIndexWhere((m) => m.role == MessageRole.user);
            
        if (userMessageIndex == -1) {
          throw ValidationError('Cannot find user message to retry');
        }

        final userMessage = _messages[userMessageIndex].content;
        await streamResponse("Retried response for: $userMessage");
        return; // Success, exit retry loop
        
      } catch (e, stackTrace) {
        retryCount++;
        developer.log(
          'Retry attempt $retryCount failed',
          error: e,
          stackTrace: stackTrace,
          name: 'ChatProvider',
          time: DateTime.now(),
        );
        
        if (retryCount >= maxRetries || !ErrorHandler.shouldRetry(e)) {
          final errorMsg = ErrorHandler.getErrorMessage(e);
          updateMessage(
            messageId,
            status: MessageStatus.error,
            errorMessage: errorMsg,
          );
          
          throw ChatError(
            'Failed to retry message after $retryCount attempts: $errorMsg',
            code: 'RETRY_FAILED',
            originalError: e,
            stackTrace: stackTrace,
          );
        }
        
        developer.log(
          'Retrying in ${math.pow(2, retryCount)} seconds',
          name: 'ChatProvider',
        );
        
        // Wait before retrying, with exponential backoff
        await Future.delayed(Duration(seconds: math.pow(2, retryCount).toInt()));
      }
    }
  }
}
