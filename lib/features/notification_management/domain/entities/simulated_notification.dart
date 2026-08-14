class SimulatedNotification {
  final String id;
  final String projectId;
  final String senderId;
  final String senderName;
  final String? senderAvatarPath;
  final String messageText;
  final String? imagePath;
  final DateTime createdAt;

  const SimulatedNotification({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarPath,
    required this.messageText,
    this.imagePath,
    required this.createdAt,
  });
}
