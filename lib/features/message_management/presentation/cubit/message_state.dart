part of 'message_cubit.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<Message> messages;

  const MessageLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class MessageSaved extends MessageState {}

class MessageError extends MessageState {
  final String message;

  const MessageError(this.message);

  @override
  List<Object?> get props => [message];
}
