import 'dart:async';

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

  StreamSubscription? _messagesSubscription;

  MessageCubit({
    required this.getMessages,
    required this.addMessage,
    required this.updateMessage,
    required this.deleteMessage,
  }) : super(MessageInitial());

  void loadMessages(
    String projectId,
  ) {
    emit(MessageLoading());

    _messagesSubscription?.cancel();

    _messagesSubscription = getMessages(projectId).listen(
      (result) {
        result.fold(
          (failure) {
            emit(
              MessageError(
                failure.message,
              ),
            );
          },
          (messages) {
            emit(
              MessageLoaded(
                messages,
              ),
            );
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
    );

    final result = await addMessage(message);

    result.fold(
      (failure) => emit(
        MessageError(
          failure.message,
        ),
      ),
      (_) {
        emit(MessageSaved());
      },
    );
  }

  Future<void> editMessage(
    Message message,
  ) async {
    final result = await updateMessage(message);

    result.fold(
      (failure) => emit(
        MessageError(
          failure.message,
        ),
      ),
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
      (failure) => emit(
        MessageError(
          failure.message,
        ),
      ),
      (_) {},
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
