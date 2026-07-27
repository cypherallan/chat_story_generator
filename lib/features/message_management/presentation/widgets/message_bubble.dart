import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    ImageProvider? image;

    if (sender.avatarPath != null) {
      if (sender.avatarPath!.startsWith('http')) {
        image = NetworkImage(sender.avatarPath!);
      } else {
        image = FileImage(File(sender.avatarPath!));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 8,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 20,
              backgroundImage: image,
              child: image == null ? Text(sender.name[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 320,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isMine ? const Color(0xFFDCF8C6) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sender.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (sender.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
