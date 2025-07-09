import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.isLoading,
    super.conversationId,
    super.userId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      content: message.content,
      role: message.role,
      timestamp: message.timestamp,
      isLoading: message.isLoading,
      conversationId: message.conversationId,
      userId: message.userId,
    );
  }
}
