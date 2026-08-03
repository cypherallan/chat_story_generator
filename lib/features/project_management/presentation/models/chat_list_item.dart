import '../../domain/entities/project.dart';

class ChatListItem {
  final Project project;

  final String chatName;
  final String? avatarPath;

  final String lastMessage;

  final DateTime? lastMessageTime;

  final int unreadCount;

  final bool pinned;
  final bool muted;
  final bool verified;

  final bool isTyping;

  final bool isOnline;

  const ChatListItem({
    required this.project,
    required this.chatName,
    this.avatarPath,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.pinned = false,
    this.muted = false,
    this.verified = false,
    this.isTyping = false,
    this.isOnline = false,
  });
}
