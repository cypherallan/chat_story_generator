import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool visible;

  const TypingIndicator({
    super.key,
    required this.visible,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final value = (_controller.value * 3 - index).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Opacity(
            opacity: 0.3 + value * 0.7,
            child: Transform.translate(
              offset: Offset(0, -2 * value),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 70,
        bottom: 6,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(0),
              _dot(1),
              _dot(2),
            ],
          ),
        ),
      ),
    );
  }
}
