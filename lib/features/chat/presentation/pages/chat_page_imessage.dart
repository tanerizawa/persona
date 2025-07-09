import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../injection_container.dart';
import '../../domain/entities/message.dart';
import '../../domain/services/chat_message_optimizer.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_bubble_imessage.dart' as imessage;
import '../widgets/chat_input_imessage.dart';

class ChatPageiMessage extends StatelessWidget {
  const ChatPageiMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ChatBloc>()..add(ChatStarted()),
      child: const ChatViewiMessage(),
    );
  }
}

class ChatViewiMessage extends StatefulWidget {
  const ChatViewiMessage({super.key});

  @override
  State<ChatViewiMessage> createState() => _ChatViewiMessageState();
}

class _ChatViewiMessageState extends State<ChatViewiMessage> {
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            );
          }

          if (state is ChatLoaded) {
            return Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildEmptyState(context)
                      : _buildMessagesList(context, state.messages, state.isLoadingMessage),
                ),
                ChatInputiMessage(
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

          return _buildEmptyState(context);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          // Avatar with online status
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C7B7F), Color(0xFF4A5568)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Online status indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Persona',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.videocam,
            color: Color(0xFF007AFF),
            size: 28,
          ),
          onPressed: () {
            // TODO: Implement video call
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.call,
            color: Color(0xFF007AFF),
            size: 24,
          ),
          onPressed: () {
            // TODO: Implement voice call
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.info_outline,
            color: Color(0xFF007AFF),
            size: 24,
          ),
          onPressed: () => _showChatInfo(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main avatar with animation
          Hero(
            tag: 'persona_avatar',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C7B7F), Color(0xFF4A5568)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Halo! Saya Persona 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'AI companion yang siap menemani perjalanan personal growth Anda',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Suggestion bubbles
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSuggestionChip(context, '💭', 'Ceritakan hari Anda'),
              _buildSuggestionChip(context, '🎯', 'Set goals personal'),
              _buildSuggestionChip(context, '🧠', 'Eksplorasi MBTI'),
              _buildSuggestionChip(context, '💪', 'Tips self-improvement'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String emoji, String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        context.read<ChatBloc>().add(ChatMessageSent(text));
        _messageController.clear();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF007AFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF007AFF).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<Message> messages, bool isLoadingMessage) {
    final expandedMessages = _expandMessagesForBubbles(messages);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: expandedMessages.length + (isLoadingMessage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == expandedMessages.length && isLoadingMessage) {
            return imessage.ChatBubble.loading(
              animationDelay: _calculateLoadingDelay(expandedMessages),
            );
          }
          
          final message = expandedMessages[index];
          final isPartOfSeries = _isPartOfCounselingSeries(message, index, expandedMessages);
          
          Duration? animationDelay = _calculateBubbleDelay(message, index, expandedMessages, isPartOfSeries);
          
          return imessage.ChatBubble(
            message: message,
            isFromUser: message.role == MessageRole.user,
            isPartOfSeries: isPartOfSeries,
            bubbleIndex: isPartOfSeries ? 1 : 0,
            animationDelay: animationDelay,
          );
        },
      ),
    );
  }

  Duration _calculateLoadingDelay(List<Message> expandedMessages) {
    if (expandedMessages.isEmpty) {
      return const Duration(milliseconds: 1500);
    }
    
    final lastMessage = expandedMessages.last;
    if (lastMessage.role == MessageRole.user) {
      final readingTime = _calculateReadingTime(lastMessage.content);
      const baseThinkingTime = Duration(milliseconds: 1800);
      return Duration(milliseconds: readingTime.inMilliseconds + baseThinkingTime.inMilliseconds);
    }
    
    return const Duration(milliseconds: 1200);
  }

  Duration? _calculateBubbleDelay(Message message, int index, List<Message> allMessages, bool isPartOfSeries) {
    if (message.role == MessageRole.user) {
      return null;
    }
    
    if (isPartOfSeries) {
      return const Duration(milliseconds: 4200);
    }
    
    final userMessageIndex = _findPreviousUserMessageIndex(index, allMessages);
    if (userMessageIndex != -1) {
      final userMessage = allMessages[userMessageIndex];
      final readingTime = _calculateReadingTime(userMessage.content);
      const thinkingTime = Duration(milliseconds: 2200);
      final formulationTime = _calculateTypingTime(message.content);
      
      return Duration(
        milliseconds: readingTime.inMilliseconds + 
                     thinkingTime.inMilliseconds + 
                     formulationTime.inMilliseconds
      );
    }
    
    return const Duration(milliseconds: 2800);
  }

  int _findPreviousUserMessageIndex(int currentIndex, List<Message> allMessages) {
    for (int i = currentIndex - 1; i >= 0; i--) {
      if (allMessages[i].role == MessageRole.user) {
        return i;
      }
    }
    return -1;
  }

  Duration _calculateReadingTime(String content) {
    final wordCount = content.split(' ').length;
    final readingTimeMs = (wordCount / 4 * 1000).clamp(500, 2000).toInt();
    return Duration(milliseconds: readingTimeMs);
  }

  Duration _calculateTypingTime(String content) {
    final charCount = content.length;
    final typingTimeMs = (charCount / 3.5 * 1000).clamp(800, 2500).toInt();
    return Duration(milliseconds: typingTimeMs);
  }

  List<Message> _expandMessagesForBubbles(List<Message> messages) {
    final expandedMessages = <Message>[];
    
    for (final message in messages) {
      if (message.role == MessageRole.assistant) {
        final optimizer = ChatMessageOptimizer();
        final optimizedBubbles = optimizer.optimizeAIResponse(message.content);
        
        if (optimizedBubbles.length > 1) {
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
          expandedMessages.add(message);
        }
      } else {
        expandedMessages.add(message);
      }
    }
    
    return expandedMessages;
  }

  bool _isPartOfCounselingSeries(Message message, int index, List<Message> allMessages) {
    if (message.id.contains('_bubble_')) {
      final bubbleIndex = int.tryParse(message.id.split('_bubble_')[1]) ?? 0;
      return bubbleIndex > 0;
    }
    
    return false;
  }

  void _showChatInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C7B7F), Color(0xFF4A5568)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'P',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          'Persona',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        const Text(
                          'AI Companion • Online',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.call,
                          label: 'Audio',
                          color: const Color(0xFF34C759),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.videocam,
                          label: 'Video',
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.mail,
                          label: 'Mail',
                          color: const Color(0xFF5856D6),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Settings list
                  _buildSettingItem(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    icon: Icons.delete_outline,
                    title: 'Clear Chat History',
                    onTap: () {
                      Navigator.pop(context);
                      _showClearChatDialog(context);
                    },
                  ),
                  _buildSettingItem(
                    icon: Icons.block,
                    title: 'Block Contact',
                    isDestructive: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement actions
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF8E8E93),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : const Color(0xFF1C1C1E),
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF8E8E93),
      ),
      onTap: onTap,
    );
  }

  void _showClearChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all chat history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<ChatBloc>().add(ChatHistoryCleared());
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
