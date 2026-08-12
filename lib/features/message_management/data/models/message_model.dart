import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.projectId,
    required super.senderId,
    super.senderName,
    required super.text,
    super.imagePath,
    required super.createdAt,
    super.status = MessageStatus.sent,
    super.isEdited = false,
    super.isDeleted = false,
    super.replyToMessageId,
    super.replyToSenderId,
    super.replyToSenderName,
    super.replyToText,
    super.reactions = const {},
    super.originalText,
    super.deletedAt,
  });

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      projectId: message.projectId,
      senderId: message.senderId,
      senderName: message.senderName,
      text: message.text,
      imagePath: message.imagePath,
      createdAt: message.createdAt,
      status: message.status,
      isEdited: message.isEdited,
      isDeleted: message.isDeleted,
      replyToMessageId: message.replyToMessageId,
      replyToSenderId: message.replyToSenderId,
      replyToSenderName: message.replyToSenderName,
      replyToText: message.replyToText,
      reactions: message.reactions,
      originalText: message.originalText,
      deletedAt: message.deletedAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      text: json['text'] as String,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MessageStatus.values.byName(
        (json['status'] as String?) ?? 'sent',
      ),
      isEdited: (json['isEdited'] as bool?) ?? false,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      replyToMessageId: json['replyToMessageId'] as String?,
      replyToSenderId: json['replyToSenderId'] as String?,
      replyToSenderName: json['replyToSenderName'] as String?,
      replyToText: json['replyToText'] as String?,
      reactions: Map<String, String>.from(
        json['reactions'] ?? {},
      ),
      originalText: json['originalText'] as String?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'replyToMessageId': replyToMessageId,
      'replyToSenderId': replyToSenderId,
      'replyToSenderName': replyToSenderName,
      'replyToText': replyToText,
      'reactions': reactions,
      'originalText': originalText,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}
