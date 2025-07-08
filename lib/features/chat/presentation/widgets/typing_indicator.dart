import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.defaultPadding / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0.0),
          _buildDot(0.2),
          _buildDot(0.4),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double animValue = (((_animationController.value + delay) % 1.0) < 0.5)
            ? ((_animationController.value + delay) % 0.5) * 2
            : 1.0 - (((_animationController.value + delay) % 0.5) * 2);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6 + (6 * animValue),
          width: 6 + (6 * animValue),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5 + (0.5 * animValue)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
