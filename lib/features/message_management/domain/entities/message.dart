import 'package:equatable/equatable.dart';
import 'message_status.dart';

class Message extends Equatable {
  final String id;
  final String projectId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isEdited;

  const Message({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.isEdited = false,
  });

  Message copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    MessageStatus? status,
    bool? isEdited,
  }) {
    return Message(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        senderId,
        text,
        createdAt,
        status,
        isEdited,
      ];
}
