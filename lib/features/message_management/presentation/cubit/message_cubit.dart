import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/usecases/add_message.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/update_message.dart';
import '../../../group_management/domain/usecases/update_project.dart';
import '../../../group_management/domain/usecases/get_projects.dart';
import '../../../../core/storage/firebase_storage_service.dart';

import 'message_cubit_send.dart';
import 'message_cubit_engagement.dart';
import 'message_cubit_delete.dart';
import '../../domain/entities/message_status.dart';
part 'message_state.dart';

class MessageCubit extends Cubit<MessageState>
    with
        MessageCubitSendMixin,
        MessageCubitEngagementMixin,
        MessageCubitDeleteMixin {
  final GetMessages getMessages;
  @override
  final AddMessage addMessage;
  @override
  final UpdateMessage updateMessage;
  @override
  final DeleteMessage deleteMessage;
  @override
  final GetProjects getProjects;
  @override
  final UpdateProject updateProject;
  @override
  final FirebaseStorageService storageService;

  final List<Message> _pendingMessages = [];
  @override
  List<Message> get pendingMessages => _pendingMessages;

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
          (failure) => emit(MessageError(failure.message)),
          (messages) {
            final mergedMessages = <String, Message>{};
            for (final message in messages) {
              mergedMessages[message.id] = message;
            }
            for (final pending
                in _pendingMessages.where((p) => p.projectId == projectId)) {
              mergedMessages.putIfAbsent(pending.id, () => pending);
            }
            final combined = mergedMessages.values.toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            emit(MessageLoaded(combined));
          },
        );
      },
    );
  }

  Future<bool> addNotificationMessage({
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

    return result.fold(
      (failure) {
        emit(MessageError(failure.message));
        return false;
      },
      (_) {
        return true;
      },
    );
  }

  @override
  Future<void> updateProjectPreview(Message message) async {
    final result = await getProjects();

    await result.fold<Future<void>>(
      (failure) async {
        emit(MessageError(failure.message));
      },
      (projects) async {
        final index = projects.indexWhere(
          (p) => p.id == message.projectId,
        );

        if (index == -1) {
          return;
        }

        final project = projects[index];

        final updated = project.copyWith(
          lastMessage: message.text,
          lastMessageImagePath: message.imagePath,
          lastMessageTime: message.createdAt,
          lastSenderId: message.senderId,
          lastMessageStatus: message.status,
        );

        final updateResult = await updateProject(updated);

        updateResult.fold(
          (failure) {
            emit(MessageError(failure.message));
          },
          (_) {},
        );
      },
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
