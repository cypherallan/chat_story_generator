import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String projectId;
  final String messageId;
  final int? triggerMessageIndex;

  final String senderId;
  final String senderName;
  final String? senderAvatarPath;

  final String messageText;
  final String? imagePath;

  const Notification({
    required this.id,
    required this.projectId,
    required this.messageId,
    this.triggerMessageIndex,
    required this.senderId,
    required this.senderName,
    this.senderAvatarPath,
    required this.messageText,
    this.imagePath,
  });

  Notification copyWith({
    String? id,
    String? projectId,
    String? messageId,
    int? triggerMessageIndex,
    String? senderId,
    String? senderName,
    String? senderAvatarPath,
    String? messageText,
    String? imagePath,
  }) {
    return Notification(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      messageId: messageId ?? this.messageId,
      triggerMessageIndex: triggerMessageIndex ?? this.triggerMessageIndex,
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
        messageId,
        triggerMessageIndex,
        senderId,
        senderName,
        senderAvatarPath,
        messageText,
        imagePath,
      ];
}
