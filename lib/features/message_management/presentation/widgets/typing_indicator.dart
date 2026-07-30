import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    super.key,
    required this.visible,
    required this.name,
  });

  final bool visible;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 4,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "$name is typing...",
          style: const TextStyle(
            color: Color(0xff00A884),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
