class SimulatedNotification {
  final String id;
  final String projectId;

  // ID of the message/notification represented by this banner.
  final String messageId;

  // Position in the replay conversation where this notification
  // should appear.
  final int? triggerMessageIndex;

  final String senderId;
  final String senderName;
  final String? senderAvatarPath;
  final String messageText;
  final String? imagePath;
  final DateTime createdAt;

  const SimulatedNotification({
    required this.id,
    required this.projectId,
    required this.messageId,
    this.triggerMessageIndex,
    required this.senderId,
    required this.senderName,
    this.senderAvatarPath,
    required this.messageText,
    this.imagePath,
    required this.createdAt,
  });
}
