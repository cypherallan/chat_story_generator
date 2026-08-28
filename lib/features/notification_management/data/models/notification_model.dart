import '../../domain/entities/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.projectId,
    required super.messageId,
    super.triggerMessageIndex,
    required super.senderId,
    required super.senderName,
    super.senderAvatarPath,
    required super.messageText,
    super.imagePath,
    required super.createdAt,
    super.groupName,
    super.groupAvatarPath,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      messageId: json['messageId'] ?? '',
      triggerMessageIndex: json['triggerMessageIndex'],
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatarPath: json['senderAvatarPath'],
      messageText: json['messageText'] ?? '',
      imagePath: json['imagePath'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      groupName: json['groupName'],
      groupAvatarPath: json['groupAvatarPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'messageId': messageId,
      'triggerMessageIndex': triggerMessageIndex,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarPath': senderAvatarPath,
      'messageText': messageText,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'groupName': groupName,
      'groupAvatarPath': groupAvatarPath,
    };
  }

  factory NotificationModel.fromEntity(Notification notification) {
    return NotificationModel(
      id: notification.id,
      projectId: notification.projectId,
      messageId: notification.messageId,
      triggerMessageIndex: notification.triggerMessageIndex,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderAvatarPath: notification.senderAvatarPath,
      messageText: notification.messageText,
      imagePath: notification.imagePath,
      createdAt: notification.createdAt,
      groupName: notification.groupName,
      groupAvatarPath: notification.groupAvatarPath,
    );
  }
}
