import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.ownerId,
    required super.participantIds,
    super.lastMessage,
    super.lastMessageTime,
    super.lastSenderId,
    super.unreadCount,
    super.pinned,
    super.muted,
    super.archived,
  });

  factory ProjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      ownerId: json['ownerId'] ?? '',
      participantIds: List<String>.from(
        json['participantIds'] ?? [],
      ),
      lastMessage: json['lastMessage'] ?? '',
      lastSenderId: json['lastSenderId'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      pinned: json['pinned'] ?? false,
      muted: json['muted'] ?? false,
      archived: json['archived'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'pinned': pinned,
      'muted': muted,
      'archived': archived,
    };
  }

  factory ProjectModel.fromEntity(
    Project project,
  ) {
    return ProjectModel(
      id: project.id,
      title: project.title,
      createdAt: project.createdAt,
      ownerId: project.ownerId,
      participantIds: project.participantIds,
      lastMessage: project.lastMessage,
      lastSenderId: project.lastSenderId,
      lastMessageTime: project.lastMessageTime,
      unreadCount: project.unreadCount,
      pinned: project.pinned,
      muted: project.muted,
      archived: project.archived,
    );
  }
}
