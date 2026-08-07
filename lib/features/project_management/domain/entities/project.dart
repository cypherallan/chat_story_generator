import 'package:equatable/equatable.dart';
import '../../../message_management/domain/entities/message_status.dart';

class Project extends Equatable {
  final String id;

  final String title;
  final String? groupImagePath;

  final DateTime createdAt;

  final String ownerId;

  final List<String> participantIds;

  // Chat preview
  final String lastMessage;
  final String? lastMessageImagePath;
  final DateTime? lastMessageTime;

  final String? lastSenderId;
  final MessageStatus? lastMessageStatus;

  final int unreadCount;

  final bool pinned;

  final bool muted;

  final bool archived;

  const Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.ownerId,
    required this.participantIds,
    this.groupImagePath,
    this.lastMessage = '',
    this.lastMessageImagePath,
    this.lastMessageTime,
    this.lastSenderId,
    this.lastMessageStatus,
    this.unreadCount = 0,
    this.pinned = false,
    this.muted = false,
    this.archived = false,
  });

  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? ownerId,
    List<String>? participantIds,
    String? groupImagePath,
    String? lastMessage,
    String? lastMessageImagePath,
    DateTime? lastMessageTime,
    String? lastSenderId,
    MessageStatus? lastMessageStatus,
    int? unreadCount,
    bool? pinned,
    bool? muted,
    bool? archived,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      participantIds: participantIds ?? this.participantIds,
      groupImagePath: groupImagePath ?? this.groupImagePath,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageImagePath: lastMessageImagePath ?? this.lastMessageImagePath,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastMessageStatus: lastMessageStatus ?? this.lastMessageStatus,
      unreadCount: unreadCount ?? this.unreadCount,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      archived: archived ?? this.archived,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        ownerId,
        participantIds,
        groupImagePath,
        lastMessage,
        lastMessageImagePath,
        lastMessageTime,
        lastSenderId,
        lastMessageStatus,
        unreadCount,
        pinned,
        muted,
        archived,
      ];
}
