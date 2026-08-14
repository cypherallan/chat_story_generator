import '../../domain/entities/replay_notification.dart';

class ReplayNotificationModel extends ReplayNotification {
  const ReplayNotificationModel({
    required super.id,
    required super.projectId,
    required super.messageId,
    required super.senderId,
    required super.senderName,
    super.senderAvatarPath,
    required super.messageText,
    super.imagePath,
  });

  factory ReplayNotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReplayNotificationModel(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      messageId: json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatarPath: json['senderAvatarPath'],
      messageText: json['messageText'] ?? '',
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarPath': senderAvatarPath,
      'messageText': messageText,
      'imagePath': imagePath,
    };
  }

  factory ReplayNotificationModel.fromEntity(
    ReplayNotification notification,
  ) {
    return ReplayNotificationModel(
      id: notification.id,
      projectId: notification.projectId,
      messageId: notification.messageId,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderAvatarPath: notification.senderAvatarPath,
      messageText: notification.messageText,
      imagePath: notification.imagePath,
    );
  }
}
