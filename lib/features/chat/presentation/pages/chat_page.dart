import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/message.dart';
import '../../domain/services/chat_message_optimizer.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble_fixed.dart';
import '../widgets/chat_input.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChatBloc>()..add(ChatStarted()),
      child: const ChatView(),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'persona_avatar_small',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Persona',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'AI Companion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatMenu(context);
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ChatSyncing) {
            return _buildSyncingState(context, state.message);
          }

          if (state is ChatLoaded) {
            return Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState(context)
                      : _buildMessagesList(context, state.messages, state.isLoadingMessage),
                ),
                ChatInput(
                  controller: _messageController,
                  onSendMessage: (message) {
                    context.read<ChatBloc>().add(ChatMessageSent(message));
                    _messageController.clear();
                  },
                  isLoading: state.isLoadingMessage,
                ),
              ],
            );
          }

          if (state is ChatError) {
            return _buildErrorState(context, state.message);
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'persona_avatar',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding * 2),
            Text(
              'Halo! Saya Persona 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding * 2),
              child: Text(
                'Saya siap menemani perjalanan personal growth Anda. Mari berbagi cerita, eksplorasi ide, atau diskusi apa pun yang ada di pikiran Anda.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding * 2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip(context, '💭 Ceritakan hari Anda'),
                _buildSuggestionChip(context, '🎯 Set goals personal'),
                _buildSuggestionChip(context, '🧠 Eksplorasi MBTI'),
                _buildSuggestionChip(context, '💪 Tips self-improvement'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
        ),
      ),
      onPressed: () {
        _messageController.text = text.substring(2); // Remove emoji
        context.read<ChatBloc>().add(ChatMessageSent(_messageController.text));
        _messageController.clear();
      },
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<Message> messages, bool isLoadingMessage) {
    // Expand messages to handle bubble splits with proper timing
    final expandedMessages = _expandMessagesForBubbles(messages);
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: expandedMessages.length + (isLoadingMessage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == expandedMessages.length && isLoadingMessage) {
          return ChatBubble.loading(
            animationDelay: _calculateLoadingDelay(expandedMessages),
          );
        }
        
        final message = expandedMessages[index];
        final isPartOfSeries = _isPartOfCounselingSeries(message, index, expandedMessages);
        
        // Calculate human-like delays for natural conversation flow
        Duration? animationDelay = _calculateBubbleDelay(message, index, expandedMessages, isPartOfSeries);
        
        return ChatBubble(
          message: message,
          isFromUser: message.role == MessageRole.user,
          isPartOfSeries: isPartOfSeries,
          bubbleIndex: isPartOfSeries ? 1 : 0,
          animationDelay: animationDelay,
        );
      },
    );
  }
  
  /// Calculate natural loading delay based on conversation context
  Duration _calculateLoadingDelay(List<Message> expandedMessages) {
    if (expandedMessages.isEmpty) {
      return const Duration(milliseconds: 1500); // Initial conversation - more thoughtful pause
    }
    
    final lastMessage = expandedMessages.last;
    if (lastMessage.role == MessageRole.user) {
      // After user message, simulate reading time + thinking
      final readingTime = _calculateReadingTime(lastMessage.content);
      final baseThinkingTime = Duration(milliseconds: 1800); // More human-like pause
      return Duration(milliseconds: readingTime.inMilliseconds + baseThinkingTime.inMilliseconds);
    }
    
    return const Duration(milliseconds: 1200);
  }
  
  /// Calculate human-like delays for bubble appearance
  Duration? _calculateBubbleDelay(Message message, int index, List<Message> allMessages, bool isPartOfSeries) {
    // User messages appear immediately (no delay)
    if (message.role == MessageRole.user) {
      return null;
    }
    
    // For AI messages, calculate based on position and context
    if (isPartOfSeries) {
      // Second bubble in series: simulate deeper thinking + formulation
      return const Duration(milliseconds: 4200); // 2.5s thinking + 1.7s formulation
    }
    
    // First AI bubble: delay after user message
    final userMessageIndex = _findPreviousUserMessageIndex(index, allMessages);
    if (userMessageIndex != -1) {
      // Calculate comprehensive response time
      final userMessage = allMessages[userMessageIndex];
      final readingTime = _calculateReadingTime(userMessage.content);
      final thinkingTime = const Duration(milliseconds: 2200); // More thoughtful pause
      final formulationTime = _calculateTypingTime(message.content);
      
      return Duration(
        milliseconds: readingTime.inMilliseconds + 
                     thinkingTime.inMilliseconds + 
                     formulationTime.inMilliseconds
      );
    }
    
    // Default delay for AI messages - more natural
    return const Duration(milliseconds: 2800);
  }
  
  /// Find index of previous user message
  int _findPreviousUserMessageIndex(int currentIndex, List<Message> allMessages) {
    for (int i = currentIndex - 1; i >= 0; i--) {
      if (allMessages[i].role == MessageRole.user) {
        return i;
      }
    }
    return -1;
  }
  
  /// Calculate reading time based on message length (human reading speed)
  Duration _calculateReadingTime(String content) {
    final wordCount = content.split(' ').length;
    // More realistic reading speed: 200-250 words per minute for comprehension
    // Plus pause for emotional processing if content seems personal
    final baseReadingTimeMs = (wordCount / 3.5 * 1000).clamp(600, 3000).toInt();
    
    // Add extra time for emotional/complex content
    final isEmotional = content.toLowerCase().contains(RegExp(r'feel|emotion|sad|happy|stress|worry|love|fear'));
    final emotionalBonus = isEmotional ? 800 : 0;
    
    return Duration(milliseconds: baseReadingTimeMs + emotionalBonus);
  }
  
  /// Calculate typing time based on response length (human typing + thinking speed)
  Duration _calculateTypingTime(String content) {
    final charCount = content.length;
    // Realistic typing speed with thinking pauses: 35-45 WPM with pauses
    final baseTypingTimeMs = (charCount / 2.8 * 1000).clamp(1000, 4000).toInt();
    
    // Add thinking pauses for complex responses
    final isComplex = content.length > 100 || content.contains('?');
    final thinkingBonus = isComplex ? 600 : 200;
    
    return Duration(milliseconds: baseTypingTimeMs + thinkingBonus);
  }

  List<Message> _expandMessagesForBubbles(List<Message> messages) {
    final expandedMessages = <Message>[];
    
    for (final message in messages) {
      if (message.role == MessageRole.assistant) {
        // Use ChatMessageOptimizer to automatically split AI responses
        final optimizer = ChatMessageOptimizer();
        final optimizedBubbles = optimizer.optimizeAIResponse(message.content);
        
        if (optimizedBubbles.length > 1) {
          // Create multiple bubble messages
          for (int i = 0; i < optimizedBubbles.length; i++) {
            final bubbleMessage = Message(
              id: '${message.id}_bubble_$i',
              content: optimizedBubbles[i].trim(),
              role: message.role,
              timestamp: message.timestamp.add(Duration(milliseconds: i * 100)),
              conversationId: message.conversationId,
            );
            expandedMessages.add(bubbleMessage);
          }
        } else {
          // Single bubble, use original message
          expandedMessages.add(message);
        }
      } else {
        // User messages remain unchanged
        expandedMessages.add(message);
      }
    }
    
    return expandedMessages;
  }

  // Helper to detect if a message is part of counseling series
  bool _isPartOfCounselingSeries(Message message, int index, List<Message> allMessages) {
    // Check if this is a split bubble (has _bubble_ in ID)
    if (message.id.contains('_bubble_')) {
      final bubbleIndex = int.tryParse(message.id.split('_bubble_')[1]) ?? 0;
      
      // If it's not the first bubble in the series, it's likely a probing/clarifying
      return bubbleIndex > 0;
    }
    
    return false;
  }

  void _showChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus Riwayat Chat'),
              subtitle: const Text('Mulai percakapan baru dari awal'),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Persona'),
              subtitle: const Text('Pelajari lebih lanjut tentang AI companion Anda'),
              onTap: () {
                Navigator.pop(context);
                _showPersonaInfo(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan Chat'),
              subtitle: const Text('Sesuaikan preferensi percakapan'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement chat settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengaturan akan segera hadir')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonaInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                'P',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Tentang Persona'),
          ],
        ),
        content: const Text(
          'Persona adalah AI companion yang dirancang khusus untuk menemani perjalanan personal growth Anda. Saya terintegrasi dengan Little Brain untuk memberikan respons yang personal dan kontekstual berdasarkan data psikologi dan mood tracking Anda.\n\nSaya di sini untuk mendengarkan, mendukung, dan membantu Anda mengeksplorasi potensi diri.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Riwayat Chat'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua riwayat percakapan? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ChatBloc>().add(ChatHistoryCleared());
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncingState(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    // Check if error is due to offline mode
    final isOfflineError = errorMessage.contains('offline') || 
                          errorMessage.contains('network') ||
                          errorMessage.contains('internet') ||
                          errorMessage.contains('connection');
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOfflineError ? Icons.wifi_off : Icons.error_outline,
                size: 64,
                color: isOfflineError 
                    ? Colors.orange.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                isOfflineError ? 'Mode Offline' : 'Terjadi Kesalahan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOfflineError 
                      ? Colors.orange
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOfflineError 
                    ? 'Chat AI tidak tersedia saat offline. Anda masih dapat melihat riwayat chat dan menggunakan fitur lokal lainnya.'
                    : errorMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (isOfflineError) ...[
                const SizedBox(height: 24),
                const Text(
                  'Fitur yang tersedia offline:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Riwayat chat lokal'),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Pelacakan mood'),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Tes psikologi'),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ChatBloc>().add(ChatStarted());
                },
                icon: Icon(isOfflineError ? Icons.refresh : Icons.refresh),
                label: Text(isOfflineError ? 'Periksa Koneksi' : 'Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
