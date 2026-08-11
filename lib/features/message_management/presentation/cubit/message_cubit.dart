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
import '../../../../core/storage/firebase_storage_service.dart';
part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final GetMessages getMessages;
  final AddMessage addMessage;
  final UpdateMessage updateMessage;
  final DeleteMessage deleteMessage;
  final GetProjects getProjects;
  final UpdateProject updateProject;
  final FirebaseStorageService storageService;
  final List<Message> _pendingMessages = [];

  StreamSubscription? _messagesSubscription;

  MessageCubit({
    required this.getMessages,
    required this.addMessage,
    required this.updateMessage,
    required this.deleteMessage,
    required this.getProjects,
    required this.updateProject,
    required this.storageService,
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
            emit(
              MessageLoaded([
                ...messages,
                ..._pendingMessages.where(
                  (pending) => pending.projectId == projectId,
                ),
              ]),
            );
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
    String? imagePath,
    Message? replyingTo,
  }) async {
    final messageId = const Uuid().v4();

    final message = Message(
      id: messageId,
      projectId: projectId,
      senderId: senderId,
      text: text,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessageId: replyingTo?.id,
      replyToSenderId: replyingTo?.senderId,
      replyToSenderName: replyingTo?.replyToSenderName ?? senderName,
      replyToText: replyingTo?.text,
    );

    // Show the message immediately in the conversation.
    _pendingMessages.add(message);

    _emitMessagesWithPending(projectId);

    // Text-only message.
    if (imagePath == null || imagePath.isEmpty) {
      final result = await addMessage(message);

      result.fold(
        (failure) {
          _pendingMessages.removeWhere(
            (m) => m.id == message.id,
          );

          emit(MessageError(failure.message));
        },
        (_) {
          _pendingMessages.removeWhere(
            (m) => m.id == message.id,
          );

          _updateProjectPreview(message);

          _simulateDelivery(message);
        },
      );

      return;
    }

    // Image message: upload in the background.
    final imageUrl = await storageService.uploadMessageImage(
      imagePath,
      messageId: message.id,
      onProgress: (_) {},
    );

    if (imageUrl == null) {
      _pendingMessages.removeWhere(
        (m) => m.id == message.id,
      );

      _emitMessagesWithPending(projectId);

      emit(
        const MessageError(
          'Failed to upload image.',
        ),
      );

      return;
    }

    // Replace the local image path with the Firebase URL.
    final uploadedMessage = message.copyWith(
      imagePath: imageUrl,
    );

    final result = await addMessage(uploadedMessage);

    result.fold(
      (failure) {
        _pendingMessages.removeWhere(
          (m) => m.id == message.id,
        );

        _emitMessagesWithPending(projectId);

        emit(MessageError(failure.message));
      },
      (_) {
        _pendingMessages.removeWhere(
          (m) => m.id == message.id,
        );

        _emitMessagesWithPending(projectId);

        _updateProjectPreview(uploadedMessage);

        _simulateDelivery(uploadedMessage);
      },
    );
  }

  void _emitMessagesWithPending(String projectId) {
    if (state is! MessageLoaded) return;

    final currentMessages = List<Message>.from(
      (state as MessageLoaded).messages,
    );

    final pendingForProject = _pendingMessages.where(
      (message) => message.projectId == projectId,
    );

    final existingIds = currentMessages.map((m) => m.id).toSet();

    for (final pending in pendingForProject) {
      if (!existingIds.contains(pending.id)) {
        currentMessages.add(pending);
      }
    }

    currentMessages.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    emit(
      MessageLoaded(currentMessages),
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
      // Keep the original text so replay can type it first
      originalText: message.originalText ?? message.text,
      text: 'This message was deleted',
      isDeleted: true,
      deletedAt: DateTime.now(),
      imagePath: null,
      replyToMessageId: null,
      replyToSenderId: null,
      replyToSenderName: null,
      replyToText: null,
    );

    final result = await updateMessage(deletedMessage);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) async {
        await _updateProjectPreview(deletedMessage);
      },
    );
  }

  Future<void> permanentlyDeleteMessage({
    required String projectId,
    required String messageId,
  }) async {
    final result = await deleteMessage(
      DeleteMessageParams(
        projectId: projectId,
        messageId: messageId,
      ),
    );

    result.fold(
      (failure) {
        emit(MessageError(failure.message));
      },
      (_) async {
        await _updateProjectPreviewAfterPermanentDelete(projectId);
      },
    );
  }

  Future<void> _updateProjectPreviewAfterPermanentDelete(
    String projectId,
  ) async {
    if (state is! MessageLoaded) return;

    final messages = (state as MessageLoaded)
        .messages
        .where((message) => message.projectId == projectId)
        .toList();

    messages.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    final result = await getProjects();

    result.fold(
      (_) {},
      (projects) async {
        final index = projects.indexWhere(
          (project) => project.id == projectId,
        );

        if (index == -1) return;

        final project = projects[index];

        // No messages remain in the conversation.
        if (messages.isEmpty) {
          final updated = project.copyWith(
            lastMessage: '',
            lastMessageImagePath: null,
            lastMessageTime: null,
            lastSenderId: null,
            lastMessageStatus: null,
          );

          await updateProject(updated);
          return;
        }

        // There are still messages, so use the newest one.
        final latestMessage = messages.last;

        final updated = project.copyWith(
          lastMessage: latestMessage.text,
          lastMessageImagePath: latestMessage.imagePath,
          lastMessageTime: latestMessage.createdAt,
          lastSenderId: latestMessage.senderId,
          lastMessageStatus: latestMessage.status,
        );

        await updateProject(updated);
      },
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

        // Get the current messages in this conversation.
        if (state is! MessageLoaded) return;

        final messages = (state as MessageLoaded)
            .messages
            .where((m) => m.projectId == message.projectId)
            .toList();

        // If there are no messages left, completely clear the preview.
        if (messages.isEmpty) {
          final updated = project.copyWith(
            lastMessage: '',
            lastMessageImagePath: null,
            lastMessageTime: null,
            lastSenderId: null,
            lastMessageStatus: null,
          );

          await updateProject(updated);
          return;
        }

        // The messages are already ordered by createdAt from Firestore.
        final latestMessage = messages.last;

        final updated = project.copyWith(
          lastMessage: latestMessage.text,
          lastMessageImagePath: latestMessage.imagePath,
          lastMessageTime: latestMessage.createdAt,
          lastSenderId: latestMessage.senderId,
          lastMessageStatus: latestMessage.status,
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
