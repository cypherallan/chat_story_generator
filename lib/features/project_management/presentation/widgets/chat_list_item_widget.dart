import 'package:flutter/material.dart';

import '../models/chat_list_item.dart';
import '../../../message_management/domain/entities/message_status.dart';
import '../../../shared/widgets/profile_avatar.dart';

class ChatListItemWidget extends StatelessWidget {
  final ChatListItem chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;

  const ChatListItemWidget({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(chat.lastMessageTime);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isSelected,
      // ignore: deprecated_member_use
      selectedTileColor: Colors.blue.withOpacity(0.15),
      leading: Stack(
        children: [
          ProfileAvatar(
            imagePath: chat.groupImagePath ?? chat.avatarPath,
            name: chat.chatName,
            radius: 28,
          ),

          // Online indicator
          if (chat.isOnline && !isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // Selection indicator
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.chatName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (chat.verified)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.verified,
                size: 18,
                color: Colors.blue,
              ),
            ),
        ],
      ),
      subtitle: chat.isTyping
          ? const Text(
              "typing...",
              style: TextStyle(
                color: Colors.green,
                fontStyle: FontStyle.italic,
              ),
            )
          : Row(
              children: [
                if (chat.isLastMessageMine) ...[
                  _ChatPreviewTicks(
                    status: chat.lastMessageStatus,
                  ),
                  const SizedBox(width: 4),
                ],
                if (chat.lastMessageImagePath != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.image,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Text(
                    chat.lastMessageImagePath != null &&
                            chat.lastMessage.isEmpty
                        ? "Photo"
                        : chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          if (chat.unreadCount > 0)
            CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xff25D366),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "";

    final now = DateTime.now();

    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return "$h:$m";
    }

    return "${time.day}/${time.month}";
  }
}

class _ChatPreviewTicks extends StatelessWidget {
  final MessageStatus? status;

  const _ChatPreviewTicks({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const SizedBox.shrink();
    }

    switch (status!) {
      case MessageStatus.sending:
        return Icon(
          Icons.schedule,
          size: 14,
          color: Colors.grey.shade500,
        );

      case MessageStatus.sent:
        return Icon(
          Icons.done,
          size: 16,
          color: Colors.grey.shade500,
        );

      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.grey.shade500,
        );

      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Color(0xff53BDEB),
        );
    }
  }
}
