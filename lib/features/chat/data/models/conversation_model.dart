import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/conversation.dart';

part 'conversation_model.g.dart';

@JsonSerializable()
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.title,
    required super.messageIds,
    required super.createdAt,
    required super.lastUpdatedAt,
    super.lastMessagePreview,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);

  factory ConversationModel.fromEntity(Conversation conversation) {
    return ConversationModel(
      id: conversation.id,
      title: conversation.title,
      messageIds: conversation.messageIds,
      createdAt: conversation.createdAt,
      lastUpdatedAt: conversation.lastUpdatedAt,
      lastMessagePreview: conversation.lastMessagePreview,
    );
  }
}
