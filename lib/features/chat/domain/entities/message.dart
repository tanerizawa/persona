import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

enum MessageRole { 
  @JsonValue('user')
  user, 
  @JsonValue('assistant')
  assistant, 
  @JsonValue('system')
  system 
}

class Message extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;
  final String? conversationId;

  const Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
    this.conversationId,
  });

  @override
  List<Object?> get props => [id, content, role, timestamp, isLoading, conversationId];

  Message copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    bool? isLoading,
    String? conversationId,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  static Message loading() {
    return Message(
      id: 'loading',
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }
}
