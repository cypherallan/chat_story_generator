part of 'playback_cubit.dart';

class PlaybackState {
  final List<Message> visibleMessages;

  final bool isPlaying;

  final bool isTyping;

  const PlaybackState({
    this.visibleMessages = const [],
    this.isPlaying = false,
    this.isTyping = false,
  });

  PlaybackState copyWith({
    List<Message>? visibleMessages,
    bool? isPlaying,
    bool? isTyping,
  }) {
    return PlaybackState(
      visibleMessages: visibleMessages ?? this.visibleMessages,
      isPlaying: isPlaying ?? this.isPlaying,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
