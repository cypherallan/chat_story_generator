import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/usecases/add_message.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/update_message.dart';
import '../../../project_management/domain/usecases/update_project.dart';
import '../../../project_management/domain/usecases/get_projects.dart';
import '../../../../core/storage/firebase_storage_service.dart';

import 'message_cubit_send.dart';
import 'message_cubit_engagement.dart';
import 'message_cubit_delete.dart';

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

  /// Refreshes a project's preview fields (last message, sender, status...)
  /// based on the current in-memory message list.
  ///
  /// Shared by the send/engagement/delete mixins so every mutation to a
  /// conversation keeps the project list preview in sync.
  @override
  Future<void> updateProjectPreview(Message message) async {
    final result = await getProjects();

    result.fold(
      (_) {},
      (projects) async {
        final index = projects.indexWhere(
          (p) => p.id == message.projectId,
        );

        if (index == -1) return;

        final project = projects[index];

        if (state is! MessageLoaded) return;

        final messages = (state as MessageLoaded)
            .messages
            .where((m) => m.projectId == message.projectId)
            .toList();

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

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
