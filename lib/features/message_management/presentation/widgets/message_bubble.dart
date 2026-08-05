import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';
import 'message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Person sender;
  final bool isMine;
  final bool isGroup;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.isMine,
    required this.isGroup,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ImageProvider? _getAvatarImage() {
    if (sender.avatarPath == null || sender.avatarPath!.isEmpty) {
      return null;
    }

    if (sender.avatarPath!.startsWith('http')) {
      return NetworkImage(sender.avatarPath!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
            minWidth: 80,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0x3325D366)
                : isMine
                    ? const Color(0xffE7FFDB)
                    : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGroup && !isMine) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: _getAvatarImage(),
                      child: sender.avatarPath == null ||
                              sender.avatarPath!.isEmpty
                          ? Text(
                              sender.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sender.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (message.replyToText != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
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
                      if (message.replyToSenderName != null)
                        Text(
                          message.replyToSenderId == message.senderId
                              ? "You"
                              : message.replyToSenderName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff25D366),
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        message.replyToText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                message.text,
                style: const TextStyle(
                  fontSize: 15.5,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (message.isEdited) ...[
                      Text(
                        'Edited',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 3),
                      MessageStatusIcon(
                        status: message.status,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
