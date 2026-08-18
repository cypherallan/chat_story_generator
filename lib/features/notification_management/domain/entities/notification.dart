import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;

  /// The conversation from which the notification was created/triggered.
  ///
  /// Example:
  /// Mbappe is currently inside Allan's conversation.
  /// This will be Allan's project ID.
  final String projectId;

  /// Kept for the notification itself.
  ///
  /// This does NOT need to exist in the replay conversation.
  final String messageId;

  /// The position in the triggering conversation where this
  /// notification should appear during replay.
  ///
  /// Example:
  /// Allan conversation has:
  ///   0 = Hi Allan
  ///   1 = Hi Mbappe
  ///   2 = How is the going man
  ///
  /// If the notification was triggered before message 2,
  /// this value is 2.
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
