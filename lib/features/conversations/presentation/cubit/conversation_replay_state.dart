part of 'conversation_replay_cubit.dart';

class ConversationReplayState {
  final List<Message> visibleMessages;

  final bool playing;
  final bool paused;
  final bool finished;

  final bool typing;

  final String? typingPersonId;

  final String? onlinePersonId;

  final int currentIndex;

  const ConversationReplayState({
    this.visibleMessages = const [],
    this.playing = false,
    this.paused = false,
    this.finished = false,
    this.typing = false,
    this.typingPersonId,
    this.onlinePersonId,
    this.currentIndex = 0,
  });

  ConversationReplayState copyWith({
    List<Message>? visibleMessages,
    bool? playing,
    bool? paused,
    bool? finished,
    bool? typing,
    String? typingPersonId,
    String? onlinePersonId,
    int? currentIndex,
  }) {
    return ConversationReplayState(
      visibleMessages: visibleMessages ?? this.visibleMessages,
      playing: playing ?? this.playing,
      paused: paused ?? this.paused,
      finished: finished ?? this.finished,
      typing: typing ?? this.typing,

      // Allow these to become null when needed.
      typingPersonId: typingPersonId,
      onlinePersonId: onlinePersonId,

      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}