import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatStarted extends ChatEvent {}

class ChatMessageSent extends ChatEvent {
  final String message;

  const ChatMessageSent(this.message);

  @override
  List<Object> get props => [message];
}

class ChatHistoryCleared extends ChatEvent {}

class ChatUserSwitched extends ChatEvent {
  final String userId;

  const ChatUserSwitched(this.userId);

  @override
  List<Object> get props => [userId];
}

class ChatSyncRequested extends ChatEvent {}
