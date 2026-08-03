import 'dart:io';

import 'package:flutter/material.dart';

import '../models/chat_list_item.dart';

class ChatListItemWidget extends StatelessWidget {
  final ChatListItem chat;
  final VoidCallback onTap;

  const ChatListItemWidget({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;

    if (chat.avatarPath != null && chat.avatarPath!.isNotEmpty) {
      if (chat.avatarPath!.startsWith('http')) {
        image = NetworkImage(chat.avatarPath!);
      } else {
        image = FileImage(File(chat.avatarPath!));
      }
    }

    final timeText = _formatTime(chat.lastMessageTime);

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: image,
            child: image == null ? Text(chat.chatName[0].toUpperCase()) : null,
          ),
          if (chat.isOnline)
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
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.chatName,
              overflow: TextOverflow.ellipsis,
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
          : Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
