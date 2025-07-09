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
  final int bubbleIndex; // For staggered animation
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
  late AnimationController _scaleController;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers with iMessage-like timing
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create smooth, natural animations
    _bounceAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: widget.isFromUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    final baseDelay = widget.animationDelay ?? const Duration(milliseconds: 200);
    final actualDelay = widget.isLoading 
        ? baseDelay.inMilliseconds + 800
        : baseDelay.inMilliseconds;
    
    Future.delayed(Duration(milliseconds: actualDelay), () {
      if (mounted) {
        // Natural entrance animation sequence
        _slideController.forward();
        
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scaleController.forward();
          }
        });
        
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _bounceController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingBubble(context);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _scaleController, _bounceController]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Transform.scale(
              scale: _bounceAnimation.value,
              child: _buildBubbleContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: EdgeInsets.only(
          left: widget.isFromUser ? 60.0 : 8.0,
          right: widget.isFromUser ? 8.0 : 60.0,
          bottom: 4.0,
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
              child: GestureDetector(
                onLongPress: () => _showBubbleMenu(context),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    minWidth: 60,
                  ),
                  decoration: _buildBubbleDecoration(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RichFormattedText(
                        text: widget.message?.content ?? '',
                        baseStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: widget.isFromUser 
                              ? Colors.white 
                              : const Color(0xFF1C1C1E),
                          height: 1.4,
                        ),
                      ),
                      
                      // iMessage-style timestamp
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(widget.message?.timestamp ?? DateTime.now()),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isFromUser 
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          
                          if (widget.isFromUser) ...[
                            const SizedBox(width: 4),
                            // iMessage-style delivery status
                            Icon(
                              Icons.done_all,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ],
                        ],
                      ),
                    ],
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
    );
  }

  BoxDecoration _buildBubbleDecoration(BuildContext context) {
    final isSecondBubble = widget.isPartOfSeries;
    
    // iMessage-inspired colors
    final userColors = [
      const Color(0xFF007AFF),  // iOS Messages blue
      const Color(0xFF0051D6),  // Darker blue for depth
    ];
    
    final aiColors = [
      const Color(0xFFE9E9EB),  // iOS Messages gray
      const Color(0xFFDDDDDF),  // Slightly darker
    ];
    
    final aiSecondBubbleColors = [
      const Color(0xFFF2F2F7),  // Lighter for follow-up
      const Color(0xFFE5E5EA),  // Subtle gradient
    ];
    
    return BoxDecoration(
      gradient: widget.isFromUser 
          ? LinearGradient(
              colors: userColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: isSecondBubble ? aiSecondBubbleColors : aiColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      borderRadius: _buildBorderRadius(),
      boxShadow: _buildShadows(),
      border: isSecondBubble && !widget.isFromUser
          ? Border.all(
              color: const Color(0xFF007AFF).withValues(alpha: 0.15),
              width: 0.5,
            )
          : null,
    );
  }

  BorderRadius _buildBorderRadius() {
    const double radius = 18.0;
    const double smallRadius = 6.0;
    
    if (widget.isFromUser) {
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(smallRadius),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(smallRadius),
        bottomRight: Radius.circular(radius),
      );
    }
  }

  List<BoxShadow> _buildShadows() {
    return [
      BoxShadow(
        color: widget.isFromUser 
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.08),
        blurRadius: _isHovered ? 12 : 8,
        offset: Offset(0, _isHovered ? 4 : 2),
        spreadRadius: _isHovered ? 1 : 0,
      ),
      if (_isHovered) BoxShadow(
        color: widget.isFromUser 
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 6),
        spreadRadius: 2,
      ),
    ];
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF6C7B7F),
                  Color(0xFF4A5568),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isUser ? 'U' : 'P',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8.0, right: 60.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(context, false),
          const SizedBox(width: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9EB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildTypingIndicator(),
          ),
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
            final animationValue = (_bounceController.value - delay).clamp(0.0, 1.0);
            final scale = 1.0 + (math.sin(animationValue * math.pi * 2) * 0.3);
            
            return Container(
              margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  void _showBubbleMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFF007AFF)),
              title: const Text('Copy Message'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.message?.content ?? ''));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            
            if (!widget.isFromUser) ListTile(
              leading: const Icon(Icons.thumb_up_outlined, color: Color(0xFF007AFF)),
              title: const Text('Like Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement message rating
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
