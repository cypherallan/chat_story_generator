import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';
import '../../domain/usecases/add_message.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/update_message.dart';
import '../../../project_management/domain/usecases/update_project.dart';
import '../../../project_management/domain/usecases/get_projects.dart';

part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final GetMessages getMessages;
  final AddMessage addMessage;
  final UpdateMessage updateMessage;
  final DeleteMessage deleteMessage;
  final GetProjects getProjects;
  final UpdateProject updateProject;

  StreamSubscription? _messagesSubscription;

  MessageCubit({
    required this.getMessages,
    required this.addMessage,
    required this.updateMessage,
    required this.deleteMessage,
    required this.getProjects,
    required this.updateProject,
  }) : super(MessageInitial());

  void loadMessages(String projectId) {
    emit(MessageLoading());

    _messagesSubscription?.cancel();

    _messagesSubscription = getMessages(projectId).listen(
      (result) {
        result.fold(
          (failure) {
            emit(MessageError(failure.message));
          },
          (messages) {
            emit(MessageLoaded(messages));
          },
        );
      },
    );
  }

  Future<void> createMessage({
    required String projectId,
    required String senderId,
    required String senderName,
    required String text,
    Message? replyingTo,
  }) async {
    final message = Message(
      id: const Uuid().v4(),
      projectId: projectId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: replyingTo?.id,
      replyToSenderId: replyingTo?.senderId,
      replyToSenderName: replyingTo?.replyToSenderName ?? senderName,
      replyToText: replyingTo?.text,
    );

    final result = await addMessage(message);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) async {
        await _updateProjectPreview(message);
        _simulateDelivery(message);
      },
    );
  }

  void _simulateDelivery(Message message) async {
    var current = message;

    await Future.delayed(const Duration(seconds: 1));

    current = current.copyWith(
      status: MessageStatus.sent,
    );

    await updateMessage(current);
    await _updateProjectPreview(current);

    await Future.delayed(const Duration(milliseconds: 500));

    current = current.copyWith(
      status: MessageStatus.delivered,
    );

    await updateMessage(current);
    await _updateProjectPreview(current);
  }

  /// Marks every message NOT sent by [currentUserId] as read.
  Future<void> markMessagesAsRead({
    required String projectId,
    required String currentUserId,
  }) async {
    if (state is! MessageLoaded) return;

    final messages = (state as MessageLoaded).messages;

    final messagesToRead = messages.where(
      (m) =>
          m.projectId == projectId &&
          m.senderId == currentUserId &&
          m.status == MessageStatus.delivered,
    );

    for (final message in messagesToRead) {
      final updatedMessage = message.copyWith(
        status: MessageStatus.read,
      );

      final result = await updateMessage(updatedMessage);

      result.fold(
        (_) {},
        (_) async {
          await _updateProjectPreview(updatedMessage);
        },
      );
    }
  }

  Future<void> editMessage(Message message) async {
    final result = await updateMessage(message);
    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) {},
    );
  }

  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (state is! MessageLoaded) return;

    final messages = (state as MessageLoaded).messages;

    final message = messages.firstWhere(
      (m) => m.id == messageId,
    );

    final updatedReactions = Map<String, String>.from(
      message.reactions,
    );

    updatedReactions[userId] = emoji;

    final updatedMessage = message.copyWith(
      reactions: updatedReactions,
    );

    final result = await updateMessage(updatedMessage);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) {},
    );
  }

  Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (state is! MessageLoaded) return;

    final messages = (state as MessageLoaded).messages;

    final message = messages.firstWhere(
      (m) => m.id == messageId,
    );

    final updatedReactions = Map<String, String>.from(
      message.reactions,
    );

    if (updatedReactions[userId] == emoji) {
      // Remove reaction if user taps the same emoji again
      updatedReactions.remove(userId);
    } else {
      // Add/change reaction
      updatedReactions[userId] = emoji;
    }

    final updatedMessage = message.copyWith(
      reactions: updatedReactions,
    );

    final result = await updateMessage(updatedMessage);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) {},
    );
  }

  Future<void> removeMessage({
    required String projectId,
    required String messageId,
  }) async {
    if (state is! MessageLoaded) return;

    final messages = (state as MessageLoaded).messages;

    final message = messages.firstWhere(
      (m) => m.id == messageId,
    );

    final deletedMessage = message.copyWith(
      text: 'This message was deleted',
      isDeleted: true,
      replyToMessageId: null,
      replyToSenderId: null,
      replyToSenderName: null,
      replyToText: null,
    );

    final result = await updateMessage(deletedMessage);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) {},
    );
  }

  Future<void> _updateProjectPreview(Message message) async {
    final result = await getProjects();

    result.fold(
      (_) {},
      (projects) async {
        final index = projects.indexWhere(
          (p) => p.id == message.projectId,
        );

        if (index == -1) return;

        final project = projects[index];

        final updated = project.copyWith(
          lastMessage: message.text,
          lastMessageTime: message.createdAt,
          lastSenderId: message.senderId,
          lastMessageStatus: message.status,
          unreadCount: message.senderId == project.ownerId
              ? project.unreadCount
              : project.unreadCount + 1,
        );

        await updateProject(updated);
      },
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
