import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Person sender;

  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 6,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(message.text),
          ],
        ),
      ),
    );
  }
}
