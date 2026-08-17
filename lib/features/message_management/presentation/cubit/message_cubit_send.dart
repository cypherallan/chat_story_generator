import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';
import '../../domain/usecases/add_message.dart';
import '../../domain/usecases/update_message.dart';
import '../../../../core/storage/firebase_storage_service.dart';
import 'message_cubit.dart';

/// Handles composing and sending new messages (text + image), including
/// the optimistic "pending" preview shown before the write completes.
mixin MessageCubitSendMixin on Cubit<MessageState> {
  AddMessage get addMessage;
  UpdateMessage get updateMessage;
  FirebaseStorageService get storageService;
  List<Message> get pendingMessages;

  Future<void> updateProjectPreview(Message message);

  Future<void> createNotificationMessage({
    required String projectId,
    required String messageId,
    required String senderId,
    required String senderName,
    required String text,
    String? imagePath,
  }) async {
    final message = Message(
      id: messageId,
      projectId: projectId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      status: MessageStatus.delivered,
      isUnread: true,
    );

    final result = await addMessage(message);

    await result.fold<Future<void>>(
      (failure) async {

        emit(MessageError(failure.message));
      },
      (savedMessage) async {


        await updateProjectPreview(savedMessage);

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
    pendingMessages.add(message);

    _emitMessagesWithPending(projectId);

    // Text-only message.
    if (imagePath == null || imagePath.isEmpty) {
      final result = await addMessage(message);

      result.fold(
        (failure) {
          pendingMessages.removeWhere(
            (m) => m.id == message.id,
          );

          emit(MessageError(failure.message));
        },
        (_) {
          pendingMessages.removeWhere(
            (m) => m.id == message.id,
          );

          updateProjectPreview(message);

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
      pendingMessages.removeWhere(
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
        pendingMessages.removeWhere(
          (m) => m.id == message.id,
        );

        _emitMessagesWithPending(projectId);

        emit(MessageError(failure.message));
      },
      (_) {
        pendingMessages.removeWhere(
          (m) => m.id == message.id,
        );

        _emitMessagesWithPending(projectId);

        updateProjectPreview(uploadedMessage);

        _simulateDelivery(uploadedMessage);
      },
    );
  }

  void _emitMessagesWithPending(String projectId) {
    if (state is! MessageLoaded) return;

    final currentMessages = List<Message>.from(
      (state as MessageLoaded).messages,
    );

    final pendingForProject = pendingMessages.where(
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
    await updateProjectPreview(current);

    await Future.delayed(const Duration(milliseconds: 500));

    current = current.copyWith(
      status: MessageStatus.delivered,
    );

    await updateMessage(current);
    await updateProjectPreview(current);
  }
}
