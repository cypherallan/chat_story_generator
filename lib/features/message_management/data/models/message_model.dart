import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.projectId,
    required super.senderId,
    required super.text,
    required super.createdAt,
    super.status = MessageStatus.sent,
    super.isEdited = false,
    super.isDeleted = false,
    super.replyToMessageId,
    super.replyToSenderId,
    super.replyToSenderName,
    super.replyToText,
  });

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      projectId: message.projectId,
      senderId: message.senderId,
      text: message.text,
      createdAt: message.createdAt,
      status: message.status,
      isEdited: message.isEdited,
      isDeleted: message.isDeleted,
      replyToMessageId: message.replyToMessageId,
      replyToSenderId: message.replyToSenderId,
      replyToSenderName: message.replyToSenderName,
      replyToText: message.replyToText,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'replyToMessageId': replyToMessageId,
      'replyToSenderId': replyToSenderId,
      'replyToSenderName': replyToSenderName,
      'replyToText': replyToText,
    };
  }
}
