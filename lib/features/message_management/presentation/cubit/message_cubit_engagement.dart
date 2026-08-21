import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/entities/message_status.dart';
import '../../domain/usecases/update_message.dart';
import 'message_cubit.dart';

/// Handles read receipts, edits, and emoji reactions on existing messages.
mixin MessageCubitEngagementMixin on Cubit<MessageState> {
  UpdateMessage get updateMessage;

  Future<void> updateProjectPreview(Message message);

  /// Marks every message NOT sent by [currentUserId] as read.
  Future<void> markMessagesAsRead({
    required String projectId,
    required String currentUserId,
  }) async {
    if (state is! MessageLoaded) return;

    final currentMessages =
        List<Message>.from((state as MessageLoaded).messages);

    final updatedMessages = <Message>[];

    for (final message in currentMessages) {
      if (message.projectId != projectId ||
          message.senderId == currentUserId ||
          !message.isUnread) {
        updatedMessages.add(message);
        continue;
      }

      final updatedMessage = message.copyWith(
        status: MessageStatus.read,
        isUnread: false,
      );

      final result = await updateMessage(updatedMessage);

      result.fold(
        (_) {
          updatedMessages.add(message);
        },
        (_) {
          updatedMessages.add(updatedMessage);
        },
      );
    }

    emit(MessageLoaded(updatedMessages));
  }

  /// Marks the current user's delivered messages as read when
  /// the other person starts typing.
  Future<void> markOutgoingMessagesAsRead({
    required String projectId,
    required String currentUserId,
  }) async {
    if (state is! MessageLoaded) return;

    final currentMessages =
        List<Message>.from((state as MessageLoaded).messages);

    final updatedMessages = <Message>[];

    for (final message in currentMessages) {
      if (message.projectId != projectId ||
          message.senderId != currentUserId ||
          message.status != MessageStatus.delivered) {
        updatedMessages.add(message);
        continue;
      }

      final updatedMessage = message.copyWith(
        status: MessageStatus.read,
      );

      final result = await updateMessage(updatedMessage);

      result.fold(
        (_) {
          updatedMessages.add(message);
        },
        (_) {
          updatedMessages.add(updatedMessage);
        },
      );
    }

    emit(MessageLoaded(updatedMessages));
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
}
