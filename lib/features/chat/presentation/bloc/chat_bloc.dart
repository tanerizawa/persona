import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../../../../core/services/user_session_service.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_conversation_history.dart';
import '../../domain/usecases/send_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationHistoryUseCase getConversationHistoryUseCase;
  final UserSessionService _userSessionService;
  
  StreamSubscription<String?>? _userSwitchSubscription;

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getConversationHistoryUseCase,
    required UserSessionService userSessionService,
  }) : _userSessionService = userSessionService,
       super(ChatInitial()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onChatMessageSent);
    on<ChatHistoryCleared>(_onChatHistoryCleared);
    on<ChatUserSwitched>(_onChatUserSwitched);
    on<ChatSyncRequested>(_onChatSyncRequested);
    
    // Listen for user switches
    _userSwitchSubscription = _userSessionService.userSwitchStream.listen((userId) {
      if (userId != null) {
        add(ChatUserSwitched(userId));
      }
    });
  }

  Future<void> _onChatStarted(ChatStarted event, Emitter<ChatState> emit) async {
    // Avoid loading state if we already have messages cached
    final currentState = state;
    if (currentState is ChatLoaded && currentState.messages.isNotEmpty) {
      // Already have data, no need to reload unless forced
      return;
    }
    
    // Only show loading for first load or when explicitly needed
    if (state is ChatInitial) {
      emit(ChatLoading());
    }
    
    final result = await getConversationHistoryUseCase();
    
    result.fold(
      (failure) => emit(const ChatError('Failed to load conversation history')),
      (messages) => emit(ChatLoaded(messages: messages)),
    );
  }

  Future<void> _onChatMessageSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Add user message immediately for better UX
      final userMessage = Message(
        id: const Uuid().v4(),
        content: event.message,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      
      final updatedMessages = [...currentState.messages, userMessage];
      emit(currentState.copyWith(
        messages: updatedMessages,
        isLoadingMessage: true,
      ));
      
      final result = await sendMessageUseCase(SendMessageParams(
        message: event.message,
        conversationHistory: currentState.messages,
      ));
      
      result.fold(
        (failure) {
          // Remove the user message and show error
          emit(currentState.copyWith(isLoadingMessage: false));
          emit(const ChatError('Failed to send message'));
        },
        (assistantMessage) {
          // Add AI response immediately without reloading entire history
          final finalMessages = [...updatedMessages, assistantMessage];
          emit(ChatLoaded(
            messages: finalMessages,
            isLoadingMessage: false,
          ));
        },
      );
    }
  }

  Future<void> _onChatHistoryCleared(ChatHistoryCleared event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      emit(const ChatLoaded(messages: []));
    }
  }

  Future<void> _onChatUserSwitched(ChatUserSwitched event, Emitter<ChatState> emit) async {
    // Clear current chat and reload for new user
    emit(ChatLoading());
    
    // Clear current data and reload chat history for new user
    final result = await getConversationHistoryUseCase();
    
    result.fold(
      (failure) => emit(const ChatError('Gagal memuat riwayat chat')),
      (messages) {
        if (messages.isEmpty) {
          // No local data for this user, show sync indicator
          emit(const ChatSyncing(message: 'Sinkronisasi data untuk akun baru...'));
          // Auto-trigger sync
          add(ChatSyncRequested());
        } else {
          emit(ChatLoaded(messages: messages));
        }
      },
    );
  }

  Future<void> _onChatSyncRequested(ChatSyncRequested event, Emitter<ChatState> emit) async {
    emit(const ChatSyncing(message: 'Mengambil data dari server...'));
    
    // TODO: Implement actual sync with backend
    // For now, simulate sync completion after delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Reload conversation history after sync
    final result = await getConversationHistoryUseCase();
    
    result.fold(
      (failure) => emit(const ChatError('Gagal sinkronisasi data')),
      (messages) => emit(ChatLoaded(messages: messages)),
    );
  }

  @override
  Future<void> close() {
    _userSwitchSubscription?.cancel();
    return super.close();
  }
}
