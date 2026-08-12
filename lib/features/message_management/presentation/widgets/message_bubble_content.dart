import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';
import 'message_reply_preview.dart';
import 'message_image_content.dart';
import 'message_text_content.dart';
import 'message_bubble_footer.dart';

class MessageBubbleContent extends StatelessWidget {
  final Message message;
  final Person sender;
  final bool isMine;
  final bool isGroup;
  final bool isLastInGroup;
  final String timeText;
  final VoidCallback? onReplyTap;

  const MessageBubbleContent({
    super.key,
    required this.message,
    required this.sender,
    required this.isMine,
    required this.isGroup,
    required this.isLastInGroup,
    required this.timeText,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGroup && !isMine && isLastInGroup)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              sender.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        if (!message.isDeleted && message.replyToText != null)
          MessageReplyPreview(
            replyToSenderName: message.replyToSenderName,
            replyToText: message.replyToText!,
            onTap: onReplyTap,
          ),
        message.imagePath != null && !message.isDeleted
            ? MessageImageContent(
                imagePath: message.imagePath!,
                text: message.text,
                isDeleted: message.isDeleted,
              )
            : MessageTextContent(
                text: message.text,
                isDeleted: message.isDeleted,
              ),
        const SizedBox(height: 2),
        MessageBubbleFooter(
          isEdited: message.isEdited,
          timeText: timeText,
          showStatusIcon: isMine && !message.isDeleted,
          status: message.status,
        ),
      ],
    );
  }
}
