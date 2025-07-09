import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputiMessage extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInputiMessage({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.isLoading = false,
  });

  @override
  State<ChatInputiMessage> createState() => _ChatInputiMessageState();
}

class _ChatInputiMessageState extends State<ChatInputiMessage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasText = false;
  bool _isExpanded = false;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    widget.controller.addListener(_onTextChanged);
    
    // Start subtle pulsing when loading
    if (widget.isLoading) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ChatInputiMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final newHasText = widget.controller.text.trim().isNotEmpty;
    final newLineCount = '\n'.allMatches(widget.controller.text).length + 1;
    final newIsExpanded = newLineCount > 1 || widget.controller.text.length > 50;
    
    if (newHasText != _hasText || newIsExpanded != _isExpanded || newLineCount != _lineCount) {
      setState(() {
        _hasText = newHasText;
        _isExpanded = newIsExpanded;
        _lineCount = newLineCount;
      });
      
      if (newHasText && !_hasText) {
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
      }
    }
  }

  void _sendMessage() {
    final message = widget.controller.text.trim();
    if (message.isNotEmpty && !widget.isLoading) {
      HapticFeedback.lightImpact();
      widget.onSendMessage(message);
      
      // Quick scale animation for send button
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxLines = _isExpanded ? 5 : 1;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Plus button (for attachments - future feature)
              _buildActionButton(
                icon: Icons.add,
                onPressed: () => _showAttachmentMenu(context),
                color: Colors.grey[600]!,
              ),
              
              const SizedBox(width: 8),
              
              // Message input field
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  constraints: BoxConstraints(
                    minHeight: 36,
                    maxHeight: maxLines * 20.0 + 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9EB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasText 
                          ? const Color(0xFF007AFF).withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          enabled: !widget.isLoading,
                          maxLines: maxLines,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: widget.isLoading 
                                ? 'Persona sedang mengetik...' 
                                : 'Ketik pesan...',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1C1C1E),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      
                      // Camera button (for future feature)
                      if (!_hasText) ...[
                        _buildActionButton(
                          icon: Icons.camera_alt,
                          onPressed: () => _showCameraOptions(context),
                          color: Colors.grey[600]!,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send button with animation
              AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value * _scaleAnimation.value,
                    child: _buildSendButton(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && !widget.isLoading;
    
    return GestureDetector(
      onTap: canSend ? _sendMessage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: canSend
              ? const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF0051D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.grey[400]!,
                    Colors.grey[500]!,
                  ],
                ),
          shape: BoxShape.circle,
          boxShadow: canSend ? [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Icon(
          widget.isLoading 
              ? Icons.more_horiz 
              : Icons.arrow_upward,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: size,
        ),
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
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
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Photos',
                    color: const Color(0xFF007AFF),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement photo picker
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: const Color(0xFF34C759),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement camera
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'File',
                    color: const Color(0xFF5856D6),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement file picker
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCameraOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    // TODO: Implement camera options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature coming soon')),
    );
  }
}
