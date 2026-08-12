import 'package:flutter/material.dart';

class MessageReplyPreview extends StatelessWidget {
  final String? replyToSenderName;
  final String replyToText;
  final VoidCallback? onTap;

  const MessageReplyPreview({
    super.key,
    required this.replyToSenderName,
    required this.replyToText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.05),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(
              color: Color(0xff25D366),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              replyToSenderName ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff25D366),
                fontSize: 12,
              ),
            ),
            Text(
              replyToText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
