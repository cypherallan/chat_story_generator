import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.projectId,
    required super.senderId,
    required super.text,
    required super.createdAt,
  });

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      projectId: message.projectId,
      senderId: message.senderId,
      text: message.text,
      createdAt: message.createdAt,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      projectId: json['projectId'],
      senderId: json['senderId'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
