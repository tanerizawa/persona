import 'package:equatable/equatable.dart';

enum MessageRole {
  user,
  assistant,
  system
}

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final String? conversationId;
  final DateTime timestamp;
  final bool isSynced;
  
  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    this.conversationId,
    required this.timestamp,
    this.isSynced = false,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: _roleFromString(json['role'] as String),
      conversationId: json['conversationId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': _roleToString(role),
      'conversationId': conversationId,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
    };
  }
  
  static MessageRole _roleFromString(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }
  
  static String _roleToString(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }
  
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    String? conversationId,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      conversationId: conversationId ?? this.conversationId,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
  
  @override
  List<Object?> get props => [id, content, role, conversationId, timestamp, isSynced];
}
