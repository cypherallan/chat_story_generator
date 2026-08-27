import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/update_message.dart';
import '../../../group_management/domain/usecases/get_projects.dart';
import '../../../group_management/domain/usecases/update_project.dart';
import 'message_cubit.dart';

mixin MessageCubitDeleteMixin on Cubit<MessageState> {
  UpdateMessage get updateMessage;
  DeleteMessage get deleteMessage;
  GetProjects get getProjects;
  UpdateProject get updateProject;

  Future<void> updateProjectPreview(Message message);

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
        await updateProjectPreview(deletedMessage);
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
}
