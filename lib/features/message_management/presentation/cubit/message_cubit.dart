import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/message.dart';
import '../../domain/usecases/add_message.dart';
import '../../domain/usecases/delete_message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/update_message.dart';

part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final GetMessages getMessages;
  final AddMessage addMessage;
  final UpdateMessage updateMessage;
  final DeleteMessage deleteMessage;

  MessageCubit({
    required this.getMessages,
    required this.addMessage,
    required this.updateMessage,
    required this.deleteMessage,
  }) : super(MessageInitial());

  Future<void> loadMessages(
    String projectId,
  ) async {
    emit(MessageLoading());

    final result = await getMessages(projectId);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (messages) => emit(MessageLoaded(messages)),
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
    );

    final result = await addMessage(message);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) async {
        emit(MessageSaved());
        await loadMessages(projectId);
      },
    );
  }

  Future<void> editMessage(
    Message message,
  ) async {
    final result = await updateMessage(message);

    result.fold(
      (failure) => emit(MessageError(failure.message)),
      (_) async {
        await loadMessages(message.projectId);
      },
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
      (_) async {
        await loadMessages(projectId);
      },
    );
  }
}
