import 'package:equatable/equatable.dart';

class ReplayNotification extends Equatable {
  final String id;

  /// The conversation this notification belongs to.
  final String projectId;

  /// The person who appears to have sent the notification.
  final String senderId;

  final String senderName;
  final String? senderAvatarPath;

  final String messageText;
  final String? imagePath;

  const ReplayNotification({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarPath,
    required this.messageText,
    this.imagePath,
  });

  ReplayNotification copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? senderName,
    String? senderAvatarPath,
    String? messageText,
    String? imagePath,
  }) {
    return ReplayNotification(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarPath: senderAvatarPath ?? this.senderAvatarPath,
      messageText: messageText ?? this.messageText,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        senderId,
        senderName,
        senderAvatarPath,
        messageText,
        imagePath,
      ];
}
