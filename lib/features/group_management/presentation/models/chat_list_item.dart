import '../../domain/entities/project.dart';
import '../../../message_management/domain/entities/message_status.dart';

class ChatListItem {
  final Project project;
  final String? lastMessageImagePath;
  final String chatName;
  final String? avatarPath;

  final String lastMessage;

  final DateTime? lastMessageTime;

  final bool isLastMessageMine;

  final MessageStatus? lastMessageStatus;

  final int unreadCount;

  final bool pinned;
  final bool muted;
  final bool verified;

  final bool isTyping;

  final bool isOnline;
  final String? groupImagePath;

  const ChatListItem({
    required this.project,
    this.lastMessageImagePath,
    required this.chatName,
    this.avatarPath,
    required this.lastMessage,
    this.lastMessageTime,
    this.isLastMessageMine = false,
    this.lastMessageStatus,
    this.unreadCount = 0,
    this.pinned = false,
    this.muted = false,
    this.verified = false,
    this.isTyping = false,
    this.isOnline = false,
    this.groupImagePath,
  });
}
