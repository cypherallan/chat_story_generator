part of 'conversation_replay_cubit.dart';

class ConversationReplayState {
  final List<Message> visibleMessages;

  final bool playing;
  final bool paused;
  final bool finished;
  final int currentIndex;
  final bool typing;
  final String? typingPersonId;
  final String? onlinePersonId;
  final String composerText;
  final String? pressedKey;
  final bool keyboardVisible;
  final bool shiftEnabled;

  const ConversationReplayState({
    this.visibleMessages = const [],
    this.playing = false,
    this.paused = false,
    this.finished = false,
    this.currentIndex = 0,
    this.typing = false,
    this.typingPersonId,
    this.pressedKey,
    this.onlinePersonId,
    this.composerText = '',
    this.keyboardVisible = false,
    this.shiftEnabled = true,
  });

  ConversationReplayState copyWith({
    List<Message>? visibleMessages,
    bool? playing,
    bool? paused,
    bool? finished,
    bool? keyboardVisible,
    int? currentIndex,
    bool? typing,
    String? typingPersonId,
    String? onlinePersonId,
    String? pressedKey,
    String? composerText,
    bool? shiftEnabled,
  }) {
    return ConversationReplayState(
      visibleMessages: visibleMessages ?? this.visibleMessages,
      playing: playing ?? this.playing,
      paused: paused ?? this.paused,
      pressedKey: pressedKey ?? this.pressedKey,
      keyboardVisible: keyboardVisible ?? this.keyboardVisible,
      finished: finished ?? this.finished,
      currentIndex: currentIndex ?? this.currentIndex,
      typing: typing ?? this.typing,
      typingPersonId: typingPersonId,
      onlinePersonId: onlinePersonId,
      composerText: composerText ?? this.composerText,
      shiftEnabled: shiftEnabled ?? this.shiftEnabled,
    );
  }
}
