import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Person sender;
  final bool isMine;

  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.70,
        ),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
          color: isMine
              ? const Color(0xffDCF8C6) // WhatsApp green
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(
              isMine ? 12 : 0,
            ),
            bottomRight: Radius.circular(
              isMine ? 0 : 12,
            ),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
