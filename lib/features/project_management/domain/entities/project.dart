import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;

  final String title;

  final DateTime createdAt;

  final String ownerId;

  final List<String> participantIds;

  // Chat preview
  final String lastMessage;

  final DateTime? lastMessageTime;

  final String? lastSenderId;

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
    this.lastMessage = '',
    this.lastMessageTime,
    this.lastSenderId,
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
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastSenderId,
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
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
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
        lastMessage,
        lastMessageTime,
        lastSenderId,
        unreadCount,
        pinned,
        muted,
        archived,
      ];
}
