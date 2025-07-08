import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_conversation_history.dart';
import '../../domain/usecases/send_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationHistoryUseCase getConversationHistoryUseCase;

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getConversationHistoryUseCase,
  }) : super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onChatMessageSent);
    on<ChatHistoryCleared>(_onChatHistoryCleared);
  }

  Future<void> _onChatStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    final result = await getConversationHistoryUseCase();
    
    result.fold(
      (failure) => emit(const ChatError('Failed to load conversation history')),
      (messages) => emit(ChatLoaded(messages: messages)),
    );
  }

  Future<void> _onChatMessageSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Add user message immediately and show loading
      emit(currentState.copyWith(isLoadingMessage: true));
      
      final result = await sendMessageUseCase(SendMessageParams(
        message: event.message,
        conversationHistory: currentState.messages,
      ));
      
      result.fold(
        (failure) {
          emit(currentState.copyWith(isLoadingMessage: false));
          emit(const ChatError('Failed to send message'));
        },
        (assistantMessage) {
          // Load updated conversation history
          _loadConversationHistory(emit);
        },
      );
    }
  }

  Future<void> _onChatHistoryCleared(ChatHistoryCleared event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      emit(const ChatLoaded(messages: []));
    }
  }

  Future<void> _loadConversationHistory(Emitter<ChatState> emit) async {
    final result = await getConversationHistoryUseCase();
    
    result.fold(
      (failure) => emit(const ChatError('Failed to load conversation history')),
      (messages) => emit(ChatLoaded(messages: messages)),
    );
  }
}
