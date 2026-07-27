import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String projectId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? text,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        senderId,
        text,
        createdAt,
      ];
}
