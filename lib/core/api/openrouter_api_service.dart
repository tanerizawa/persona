import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';

part 'openrouter_api_service.g.dart';

@RestApi(baseUrl: 'https://openrouter.ai/api/v1')
abstract class OpenRouterApiService {
  factory OpenRouterApiService(Dio dio, {String baseUrl}) = _OpenRouterApiService;

  @POST('/chat/completions')
  Future<ChatCompletionResponse> createChatCompletion(
    @Body() ChatCompletionRequest request,
  );

  @GET('/models')
  Future<List<AIModel>> getAvailableModels();
}

@JsonSerializable()
class ChatCompletionRequest {
  final String model;
  final List<ChatMessage> messages;
  @JsonKey(name: 'max_tokens')
  final int? maxTokens;
  final double? temperature;
  @JsonKey(name: 'top_p')
  final double? topP;
  @JsonKey(name: 'frequency_penalty')
  final double? frequencyPenalty;
  @JsonKey(name: 'presence_penalty')
  final double? presencePenalty;

  ChatCompletionRequest({
    required this.model,
    required this.messages,
    this.maxTokens,
    this.temperature,
    this.topP,
    this.frequencyPenalty,
    this.presencePenalty,
  });

  factory ChatCompletionRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatCompletionRequestToJson(this);
}

@JsonSerializable()
class ChatMessage {
  final String role;
  final String content;

  ChatMessage({
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatChoice> choices;
  final Usage usage;

  ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatCompletionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatCompletionResponseToJson(this);
}

@JsonSerializable()
class ChatChoice {
  final int index;
  final ChatMessage message;
  @JsonKey(name: 'finish_reason')
  final String finishReason;

  ChatChoice({
    required this.index,
    required this.message,
    required this.finishReason,
  });

  factory ChatChoice.fromJson(Map<String, dynamic> json) =>
      _$ChatChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$ChatChoiceToJson(this);
}

@JsonSerializable()
class Usage {
  @JsonKey(name: 'prompt_tokens')
  final int promptTokens;
  @JsonKey(name: 'completion_tokens')
  final int completionTokens;
  @JsonKey(name: 'total_tokens')
  final int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);

  Map<String, dynamic> toJson() => _$UsageToJson(this);
}

@JsonSerializable()
class AIModel {
  final String id;
  final String name;
  final String description;
  final Pricing pricing;

  AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.pricing,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) => _$AIModelFromJson(json);

  Map<String, dynamic> toJson() => _$AIModelToJson(this);
}

@JsonSerializable()
class Pricing {
  final String prompt;
  final String completion;

  Pricing({
    required this.prompt,
    required this.completion,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) => _$PricingFromJson(json);

  Map<String, dynamic> toJson() => _$PricingToJson(this);
}
