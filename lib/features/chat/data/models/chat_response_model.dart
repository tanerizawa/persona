import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_response_model.g.dart';

@JsonSerializable()
class ChatResponseModel extends Equatable {
  final bool success;
  final ChatResponseData? data;
  final String? error;
  final String? timestamp;
  
  const ChatResponseModel({
    required this.success,
    this.data,
    this.error,
    this.timestamp,
  });
  
  factory ChatResponseModel.fromJson(Map<String, dynamic> json) => 
      _$ChatResponseModelFromJson(json);
      
  Map<String, dynamic> toJson() => _$ChatResponseModelToJson(this);
  
  @override
  List<Object?> get props => [success, data, error, timestamp];
}

@JsonSerializable()
class ChatResponseData extends Equatable {
  final String text;
  final String conversationId;
  final String model;
  
  const ChatResponseData({
    required this.text,
    required this.conversationId,
    required this.model,
  });
  
  factory ChatResponseData.fromJson(Map<String, dynamic> json) => 
      _$ChatResponseDataFromJson(json);
      
  Map<String, dynamic> toJson() => _$ChatResponseDataToJson(this);
  
  @override
  List<Object> get props => [text, conversationId, model];
}
