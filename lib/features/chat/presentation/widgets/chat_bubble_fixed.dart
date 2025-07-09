import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../domain/entities/message.dart';
import 'rich_formatted_text.dart';

class ChatBubble extends StatefulWidget {
  final Message? message;
  final bool isFromUser;
  final bool isLoading;
  final bool isPartOfSeries;
  final int bubbleIndex;
  final Duration? animationDelay;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isFromUser,
    this.isPartOfSeries = false,
    this.bubbleIndex = 0,
    this.animationDelay,
  }) : isLoading = false;

  const ChatBubble.loading({
    super.key,
    this.bubbleIndex = 0,
    this.animationDelay,
  })  : message = null,
        isFromUser = false,
        isLoading = true,
        isPartOfSeries = false;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _slideController;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isFromUser ? 0.3 : -0.3, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _startAnimations();
  }
  
  void _startAnimations() {
    final baseDelay = widget.animationDelay ?? Duration(milliseconds: widget.bubbleIndex * 200);
    
    Future.delayed(baseDelay, () {
      if (mounted) {
        _slideController.forward();
        _bounceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: Container(
          margin: EdgeInsets.only(
            left: widget.isFromUser ? 60 : 16,
            right: widget.isFromUser ? 16 : 60,
            bottom: 8,
          ),
          child: Row(
            mainAxisAlignment: widget.isFromUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isFromUser) ...[
                _buildAvatar(context, false),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onLongPress: () => _showMessageOptions(context),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: _buildBubbleDecoration(context),
                      child: ClipRRect(
                        borderRadius: _buildBubbleBorderRadius(),
                        child: _buildBubbleContent(context),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isFromUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(context, true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingIndicator(),
            const SizedBox(width: 8),
            Text(
              'Persona sedang mengetik...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final content = widget.message?.content ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichFormattedText(
            text: content,
            baseStyle: TextStyle(
              color: widget.isFromUser ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          _buildTimestamp(context),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _bounceController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animValue = (_bounceController.value - delay).clamp(0.0, 1.0);
            final bounce = math.sin(animValue * math.pi * 2) * 0.5 + 0.5;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Transform.translate(
                offset: Offset(0, -bounce * 3),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final message = widget.message;
    if (message == null) return const SizedBox.shrink();
    
    final time = TimeOfDay.fromDateTime(message.timestamp);
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return Align(
      alignment: widget.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        timeString,
        style: TextStyle(
          color: widget.isFromUser 
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  BoxDecoration _buildBubbleDecoration(BuildContext context) {
    final isSecondBubble = widget.isPartOfSeries && widget.bubbleIndex > 0;
    final userBubbleColors = [
      const Color(0xFF007AFF),
      const Color(0xFF0051D5),
    ];
    
    final aiBubbleColors = [
      Colors.grey[100]!,
      Colors.grey[50]!,
    ];
    
    final aiSecondBubbleColors = [
      const Color(0xFFF0F8FF),
      const Color(0xFFE8F4FD),
    ];

    return BoxDecoration(
      gradient: widget.isFromUser
          ? LinearGradient(
              colors: userBubbleColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: isSecondBubble ? aiSecondBubbleColors : aiBubbleColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderRadius: _buildBubbleBorderRadius(),
      boxShadow: [
        BoxShadow(
          color: widget.isFromUser
              ? const Color(0xFF007AFF).withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.1),
          blurRadius: _isHovered ? 12 : 8,
          offset: const Offset(0, 2),
          spreadRadius: _isHovered ? 1 : 0,
        ),
      ],
    );
  }
  
  BorderRadius _buildBubbleBorderRadius() {
    const double standardRadius = 18.0;
    const double smallRadius = 6.0;
    
    if (widget.isFromUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(standardRadius),
        topRight: Radius.circular(standardRadius),
        bottomLeft: Radius.circular(standardRadius),
        bottomRight: Radius.circular(smallRadius),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(standardRadius),
        topRight: Radius.circular(standardRadius),
        bottomLeft: Radius.circular(smallRadius),
        bottomRight: Radius.circular(standardRadius),
      );
    }
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return Hero(
      tag: isUser ? 'user_avatar' : 'persona_avatar',
      child: CircleAvatar(
        radius: 18,
        backgroundColor: isUser 
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.primary,
        child: Icon(
          isUser ? Icons.person : Icons.psychology,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final message = widget.message;
    if (message == null) return;

    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            if (!widget.isFromUser) ...[
              ListTile(
                leading: const Icon(Icons.thumb_up_outlined),
                title: const Text('Good Response'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement feedback
                },
              ),
              ListTile(
                leading: const Icon(Icons.thumb_down_outlined),
                title: const Text('Poor Response'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement feedback
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
