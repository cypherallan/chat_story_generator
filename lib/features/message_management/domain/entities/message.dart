import 'package:equatable/equatable.dart';
import 'message_status.dart';

class Message extends Equatable {
  final String id;
  final String projectId;
  final String senderId;
  final String? senderName;
  final String text;
  final String? imagePath;
  final DateTime createdAt;
  final MessageStatus status;
  final bool isUnread;
  final bool isDeleted;
  final bool isEdited;
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final String? replyToText;
  final Map<String, String> reactions;

  final String? originalText;
  final DateTime? deletedAt;

  const Message({
    required this.id,
    required this.projectId,
    required this.senderId,
    this.senderName,
    required this.text,
    this.imagePath,
    required this.createdAt,
    this.status = MessageStatus.sent,
    this.isUnread = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToText,
    this.reactions = const {},
    this.originalText,
    this.deletedAt,
  });

  Message copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? senderName,
    String? text,
    String? imagePath,
    DateTime? createdAt,
    MessageStatus? status,
    bool? isUnread,
    bool? isEdited,
    bool? isDeleted,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToText,
    Map<String, String>? reactions,
    String? originalText,
    DateTime? deletedAt,
  }) {
    return Message(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isUnread: isUnread ?? this.isUnread,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToText: replyToText ?? this.replyToText,
      reactions: reactions ?? this.reactions,
      originalText: originalText ?? this.originalText,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        senderId,
        senderName,
        text,
        imagePath,
        createdAt,
        status,
        isUnread,
        isEdited,
        isDeleted,
        replyToMessageId,
        replyToSenderId,
        replyToSenderName,
        replyToText,
        reactions,
        originalText,
        deletedAt,
      ];
}
