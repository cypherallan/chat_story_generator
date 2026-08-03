import '../../domain/entities/project.dart';
import '../../../message_management/domain/entities/message_status.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.ownerId,
    required super.participantIds,
    super.groupImagePath,
    super.lastMessage,
    super.lastMessageTime,
    super.lastSenderId,
    super.lastMessageStatus,
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
      groupImagePath: json['groupImagePath'],
      lastMessage: json['lastMessage'] ?? '',
      lastSenderId: json['lastSenderId'],
      lastMessageStatus: json['lastMessageStatus'] != null
          ? MessageStatus.values.firstWhere(
              (e) => e.name == json['lastMessageStatus'],
            )
          : null,
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
      'groupImagePath': groupImagePath,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageStatus': lastMessageStatus?.name,
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
      groupImagePath: project.groupImagePath,
      lastMessage: project.lastMessage,
      lastSenderId: project.lastSenderId,
      lastMessageStatus: project.lastMessageStatus,
      lastMessageTime: project.lastMessageTime,
      unreadCount: project.unreadCount,
      pinned: project.pinned,
      muted: project.muted,
      archived: project.archived,
    );
  }
}
