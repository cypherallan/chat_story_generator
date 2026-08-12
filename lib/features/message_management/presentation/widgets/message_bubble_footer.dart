import 'package:flutter/material.dart';

import '../../domain/entities/message_status.dart';
import 'message_status_icon.dart';

class MessageBubbleFooter extends StatelessWidget {
  final bool isEdited;
  final String timeText;
  final bool showStatusIcon;
  final MessageStatus status;

  const MessageBubbleFooter({
    super.key,
    required this.isEdited,
    required this.timeText,
    required this.showStatusIcon,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEdited)
            const Text(
              "Edited",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          if (showStatusIcon) ...[
            const SizedBox(width: 3),
            MessageStatusIcon(
              status: status,
            )
          ]
        ],
      ),
    );
  }
}
