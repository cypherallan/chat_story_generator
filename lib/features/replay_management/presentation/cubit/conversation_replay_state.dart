import 'package:equatable/equatable.dart';

import '../../../message_management/domain/entities/message.dart';

enum ReplayScreen {
  home,
  conversation,
}

class ConversationReplayState extends Equatable {
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
  final bool shiftPressed;
  final bool emojiKeyboardVisible;
  final String? pressedEmoji;
  final List<String> availableEmojis;
  final String? lastPressedEmoji;
  final int emojiPressCount;
  final ReplayScreen screen;
  final String? currentProjectId;

  const ConversationReplayState({
    this.visibleMessages = const [],
    this.playing = false,
    this.paused = false,
    this.finished = false,
    this.currentIndex = 0,
    this.typing = false,
    this.typingPersonId,
    this.onlinePersonId,
    this.composerText = '',
    this.pressedKey,
    this.keyboardVisible = false,
    this.shiftEnabled = true,
    this.shiftPressed = false,
    this.emojiKeyboardVisible = false,
    this.pressedEmoji,
    this.availableEmojis = const [],
    this.lastPressedEmoji,
    this.emojiPressCount = 0,
    this.screen = ReplayScreen.home,
    this.currentProjectId,
  });

  ConversationReplayState copyWith({
    List<Message>? visibleMessages,
    bool? playing,
    bool? paused,
    bool? finished,
    int? currentIndex,
    bool? typing,
    String? typingPersonId,
    String? onlinePersonId,
    String? composerText,
    String? pressedKey,
    bool? keyboardVisible,
    bool? shiftEnabled,
    bool? shiftPressed,
    bool? emojiKeyboardVisible,
    String? pressedEmoji,
    List<String>? availableEmojis,
    String? lastPressedEmoji,
    int? emojiPressCount,
    ReplayScreen? screen,
    String? currentProjectId,
  }) {
    return ConversationReplayState(
      visibleMessages:
          visibleMessages ?? this.visibleMessages,
      playing: playing ?? this.playing,
      paused: paused ?? this.paused,
      finished: finished ?? this.finished,
      currentIndex:
          currentIndex ?? this.currentIndex,
      typing: typing ?? this.typing,
      typingPersonId:
          typingPersonId ?? this.typingPersonId,
      onlinePersonId:
          onlinePersonId ?? this.onlinePersonId,
      composerText:
          composerText ?? this.composerText,
      pressedKey:
          pressedKey ?? this.pressedKey,
      keyboardVisible:
          keyboardVisible ?? this.keyboardVisible,
      shiftEnabled:
          shiftEnabled ?? this.shiftEnabled,
      shiftPressed:
          shiftPressed ?? this.shiftPressed,
      emojiKeyboardVisible:
          emojiKeyboardVisible ??
              this.emojiKeyboardVisible,
      pressedEmoji:
          pressedEmoji ?? this.pressedEmoji,
      availableEmojis:
          availableEmojis ?? this.availableEmojis,
      lastPressedEmoji:
          lastPressedEmoji ?? this.lastPressedEmoji,
      emojiPressCount:
          emojiPressCount ?? this.emojiPressCount,
      screen: screen ?? this.screen,
      currentProjectId:
          currentProjectId ?? this.currentProjectId,
    );
  }

  @override
  List<Object?> get props => [
        visibleMessages,
        playing,
        paused,
        finished,
        currentIndex,
        typing,
        typingPersonId,
        onlinePersonId,
        composerText,
        pressedKey,
        keyboardVisible,
        shiftEnabled,
        shiftPressed,
        emojiKeyboardVisible,
        pressedEmoji,
        availableEmojis,
        lastPressedEmoji,
        emojiPressCount,
        screen,
        currentProjectId,
      ];
}