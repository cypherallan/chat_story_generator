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
    required String text,
  }) async {
    final message = Message(
      id: const Uuid().v4(),
      projectId: projectId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
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

  /// Simulated network flow:
  /// sending → sent (1 sec) → delivered (0.5 sec) → read (1 sec)
  void _simulateDelivery(Message message) async {
    var current = message;

    await Future.delayed(const Duration(seconds: 1));

    current = current.copyWith(
      status: MessageStatus.sent,
    );

    await updateMessage(current);

    await Future.delayed(const Duration(milliseconds: 500));

    current = current.copyWith(
      status: MessageStatus.delivered,
    );

    await Future.delayed(const Duration(milliseconds: 1500));

    current = current.copyWith(
      status: MessageStatus.read,
    );

    await updateMessage(current);

    await updateMessage(current);
  }

  /// Marks every message NOT sent by [currentUserId] as read.
  Future<void> markMessagesAsRead({
    required String projectId,
    required String currentUserId,
  }) async {
    if (state is! MessageLoaded) return;

    final messages = (state as MessageLoaded).messages;
    final unread = messages.where(
      (m) => m.senderId != currentUserId && m.status != MessageStatus.read,
    );

    for (final msg in unread) {
      final result = await updateMessage(
        msg.copyWith(status: MessageStatus.read),
      );
      result.fold((_) {}, (_) {});
    }
  }

  Future<void> editMessage(Message message) async {
    final result = await updateMessage(message);
    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) {},
    );
  }

  Future<void> removeMessage({
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
