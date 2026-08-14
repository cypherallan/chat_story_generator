class SimulatedNotification {
  final String id;
  final String projectId;

  // ID of the message/notification represented by this banner.
  final String messageId;

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
    required this.senderId,
    required this.senderName,
    this.senderAvatarPath,
    required this.messageText,
    this.imagePath,
    required this.createdAt,
  });
}