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
    };
  }
}
