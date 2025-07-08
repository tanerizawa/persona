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
  
  @override
  List<Object?> get props => [id, title, messageIds, createdAt, lastUpdatedAt, lastMessagePreview];
}
