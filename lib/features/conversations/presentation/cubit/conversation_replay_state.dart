part of 'conversation_replay_cubit.dart';

class ConversationReplayState {
  final List<Message> visibleMessages;

  final bool playing;

  final bool typing;

  final String? typingPersonId;

  const ConversationReplayState({
    this.visibleMessages = const [],
    this.playing = false,
    this.typing = false,
    this.typingPersonId,
  });

  ConversationReplayState copyWith({
    List<Message>? visibleMessages,
    bool? playing,
    bool? typing,
    String? typingPersonId,
  }) {
    return ConversationReplayState(
      visibleMessages: visibleMessages ?? this.visibleMessages,
      playing: playing ?? this.playing,
      typing: typing ?? this.typing,
      typingPersonId: typingPersonId ?? this.typingPersonId,
    );
  }
}
