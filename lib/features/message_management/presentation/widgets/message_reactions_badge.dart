import 'package:flutter/material.dart';

class MessageReactionsBadge extends StatelessWidget {
  final bool isMine;
  final Iterable<String> reactions;

  const MessageReactionsBadge({
    super.key,
    required this.isMine,
    required this.reactions,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -12,
      left: isMine ? null : 12,
      right: isMine ? 12 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          reactions.join(' '),
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
