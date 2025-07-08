import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool isLoadingMessage;

  const ChatLoaded({
    required this.messages,
    this.isLoadingMessage = false,
  });

  @override
  List<Object> get props => [messages, isLoadingMessage];

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? isLoadingMessage,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isLoadingMessage: isLoadingMessage ?? this.isLoadingMessage,
    );
  }
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
