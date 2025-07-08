import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final List<String> messageIds;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String? lastMessagePreview;
  
  const Conversation({
    required this.id,
    required this.title,
    required this.messageIds,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.lastMessagePreview,
  });
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      messageIds: (json['messageIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messageIds': messageIds,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'lastMessagePreview': lastMessagePreview,
    };
  }
  
  Conversation copyWith({
    String? id,
    String? title,
    List<String>? messageIds,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? lastMessagePreview,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messageIds: messageIds ?? this.messageIds,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
  
  @override
  List<Object?> get props => [id, title, messageIds, createdAt, lastUpdatedAt, lastMessagePreview];
}
