import 'package:uuid/uuid.dart';
import 'dart:convert';

enum MessageRole {
  user,
  assistant,
  system,
}

enum MessageStatus {
  sending,
  sent,
  error,
  typing,
}

class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final String? errorMessage;

  Message({
    required this.content,
    required this.role,
    this.status = MessageStatus.sent,
    this.errorMessage,
    String? id,
  })  : id = id ?? const Uuid().v4(),
        timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'role': role.toString(),
    'timestamp': timestamp.toIso8601String(),
    'status': status.toString(),
    'errorMessage': errorMessage,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    content: json['content'],
    role: MessageRole.values.firstWhere(
      (e) => e.toString() == json['role'],
    ),
    status: MessageStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
    ),
    errorMessage: json['errorMessage'],
  );

  Message copyWith({
    String? content,
    MessageRole? role,
    MessageStatus? status,
    String? errorMessage,
  }) {
    return Message(
      id: id,
      content: content ?? this.content,
      role: role ?? this.role,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
