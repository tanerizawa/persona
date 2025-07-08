// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatResponseModel _$ChatResponseModelFromJson(Map<String, dynamic> json) =>
    ChatResponseModel(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : ChatResponseData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$ChatResponseModelToJson(ChatResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
      'timestamp': instance.timestamp,
    };

ChatResponseData _$ChatResponseDataFromJson(Map<String, dynamic> json) =>
    ChatResponseData(
      text: json['text'] as String,
      conversationId: json['conversationId'] as String,
      model: json['model'] as String,
    );

Map<String, dynamic> _$ChatResponseDataToJson(ChatResponseData instance) =>
    <String, dynamic>{
      'text': instance.text,
      'conversationId': instance.conversationId,
      'model': instance.model,
    };
