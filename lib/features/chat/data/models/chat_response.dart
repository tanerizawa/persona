import 'package:equatable/equatable.dart';

class ChatResponse extends Equatable {
  final bool success;
  final String text;
  final String conversationId;
  final String model;
  final String? error;
  
  const ChatResponse({
    required this.success,
    required this.text,
    required this.conversationId,
    required this.model,
    this.error,
  });
  
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    
    return ChatResponse(
      success: json['success'] as bool,
      text: data?['text'] as String? ?? '',
      conversationId: data?['conversationId'] as String? ?? '',
      model: data?['model'] as String? ?? '',
      error: json['error'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': {
        'text': text,
        'conversationId': conversationId,
        'model': model,
      },
      'error': error,
    };
  }
  
  ChatResponse copyWith({
    bool? success,
    String? text,
    String? conversationId,
    String? model,
    String? error,
  }) {
    return ChatResponse(
      success: success ?? this.success,
      text: text ?? this.text,
      conversationId: conversationId ?? this.conversationId,
      model: model ?? this.model,
      error: error ?? this.error,
    );
  }
  
  @override
  List<Object?> get props => [success, text, conversationId, model, error];
}
