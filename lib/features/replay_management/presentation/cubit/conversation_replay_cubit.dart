import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';
import 'conversation_replay_state.dart';

class ConversationReplayCubit extends Cubit<ConversationReplayState> {
  ConversationReplayCubit() : super(const ConversationReplayState());

  final List<Message> _messages = [];
  final Random _random = Random();

  Timer? _timer;

  String _ownerId = '';

  String get ownerId => _ownerId;

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  void showHome() {
    _timer?.cancel();

    emit(
      state.copyWith(
        screen: ReplayScreen.home,
        currentProjectId: null,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );
  }

  void openConversation(String projectId) {
    _timer?.cancel();

    emit(
      state.copyWith(
        screen: ReplayScreen.conversation,
        currentProjectId: projectId,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );
  }

  void goBackToHome() {
    showHome();
  }

  // ---------------------------------------------------------------------------
  // LOAD REPLAY
  // ---------------------------------------------------------------------------

  void load(
    List<Message> messages,
    String ownerId,
  ) {
    _timer?.cancel();

    _messages
      ..clear()
      ..addAll(messages);

    _ownerId = ownerId;

    final Set<String> emojiSet = {};

    for (final message in messages) {
      for (final character in message.text.characters) {
        if (_isEmoji(character)) {
          emojiSet.add(character);
        }
      }
    }

    emit(
      ConversationReplayState(
        availableEmojis: emojiSet.toList(),
        screen: ReplayScreen.home,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLAYBACK
  // ---------------------------------------------------------------------------

  void play() {
    if (state.playing || state.finished) {
      return;
    }

    emit(
      state.copyWith(
        playing: true,
        paused: false,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
      ),
    );

    _playNext();
  }

  void pause() {
    _timer?.cancel();

    emit(
      state.copyWith(
        playing: false,
        paused: true,
        typing: false,
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
      ),
    );
  }

  void stop() {
    _timer?.cancel();

    emit(
      const ConversationReplayState(
        keyboardVisible: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLAY NEXT MESSAGE
  // ---------------------------------------------------------------------------

  void _playNext() {
    if (!state.playing) {
      return;
    }

    if (state.currentIndex >= _messages.length) {
      emit(
        state.copyWith(
          playing: false,
          finished: true,
          typing: false,
          keyboardVisible: false,
          emojiKeyboardVisible: false,
          composerText: '',
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
          shiftPressed: false,
        ),
      );

      return;
    }

    final message = _messages[state.currentIndex];

    if (message.senderId == _ownerId) {
      _typeOwnerMessage(message);
    } else {
      _typeOtherPersonMessage(message);
    }
  }

  // ---------------------------------------------------------------------------
  // OTHER PERSON TYPING
  //
  // The actual message remains hidden while the "typing..." indicator is shown.
  // The delay is based on the length and structure of the message so short
  // messages are quick and longer messages take noticeably longer.
  // ---------------------------------------------------------------------------

  void _typeOtherPersonMessage(Message message) {
    final delay = _humanTypingDuration(message.text);

    emit(
      state.copyWith(
        typing: true,
        typingPersonId: message.senderId,
        onlinePersonId: message.senderId,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );

    _timer = Timer(
      delay,
      () {
        if (!state.playing) {
          return;
        }

        final updatedMessages = List<Message>.from(state.visibleMessages)
          ..add(message);

        emit(
          state.copyWith(
            typing: false,
            typingPersonId: null,
            visibleMessages: updatedMessages,
            currentIndex: state.currentIndex + 1,
          ),
        );

        _timer = Timer(
          const Duration(milliseconds: 650),
          _playNext,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VISUAL SWIPE + REPLY PREVIEW
  // ---------------------------------------------------------------------------

  void _performSwipeThenType(Message message) {
    final targetId = message.replyToMessageId!;

    // Make sure the target message is already visible
    final targetExists = state.visibleMessages.any((m) => m.id == targetId);

    if (!targetExists) {
      // Fallback – just type without swipe
      _startOwnerTyping(message);
      return;
    }

    // 1. Start swipe animation
    emit(
      state.copyWith(
        swipingMessageId: targetId,
        swipeOffset: 0,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        clearReplyPreview: true,
      ),
    );

    // Animate the swipe over ~450 ms
    const steps = 12;
    const stepDuration = Duration(milliseconds: 35);
    int step = 0;

    void animateStep() {
      if (!state.playing) return;

      step++;
      final progress = step / steps;
      final offset = 80.0 * progress; // same max as MessageBubble

      emit(
        state.copyWith(
          swipeOffset: offset,
        ),
      );

      if (step < steps) {
        _timer = Timer(stepDuration, animateStep);
      } else {
        // 2. Swipe finished → show reply preview and start typing
        _timer = Timer(const Duration(milliseconds: 180), () {
          if (!state.playing) return;

          emit(
            state.copyWith(
              clearSwipe: true, // hide the swipe visual
              replyPreviewText: message.replyToText,
              replyPreviewSenderName: message.replyToSenderName,
            ),
          );

          // Small pause so user can see the preview appear
          _timer = Timer(const Duration(milliseconds: 350), () {
            if (!state.playing) return;
            _startOwnerTyping(message);
          });
        });
      }
    }

    // Small delay before the swipe starts (feels more natural)
    _timer = Timer(const Duration(milliseconds: 300), animateStep);
  }

  void _startOwnerTyping(Message message) {
    final characters = message.text.characters.toList();

    int characterIndex = 0;
    String typedText = '';

    emit(
      state.copyWith(
        composerText: '',
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftEnabled: true,
        shiftPressed: true,
        // keep the reply preview while typing
      ),
    );

    _timer = Timer(
      const Duration(milliseconds: 120),
      () {
        if (!state.playing) return;

        emit(
          state.copyWith(
            shiftPressed: false,
          ),
        );

        _typeNextOwnerCharacter(
          message,
          characters,
          characterIndex,
          typedText,
        );
      },
    );
  }

  void _typeOwnerMessage(Message message) {
    if (message.replyToMessageId != null && message.replyToText != null) {
      _performSwipeThenType(message);
      return;
    }
    final characters = message.text.characters.toList();

    int characterIndex = 0;
    String typedText = '';

    emit(
      state.copyWith(
        composerText: '',
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftEnabled: true,
        shiftPressed: true,
      ),
    );

    _timer = Timer(
      const Duration(milliseconds: 120),
      () {
        if (!state.playing) return;

        emit(
          state.copyWith(
            shiftPressed: false,
          ),
        );

        _typeNextOwnerCharacter(
          message,
          characters,
          characterIndex,
          typedText,
        );
      },
    );
  }

  void _typeNextOwnerCharacter(
    Message message,
    List<String> characters,
    int characterIndex,
    String typedText,
  ) {
    if (!state.playing) {
      return;
    }

    // ---------------------------------------------------------------
    // FINISHED TYPING
    // ---------------------------------------------------------------

    if (characterIndex >= characters.length) {
      final updatedMessages = List<Message>.from(state.visibleMessages)
        ..add(message);

      emit(
        state.copyWith(
          composerText: '',
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
          shiftPressed: false,
          emojiKeyboardVisible: false,
          keyboardVisible: true,
          visibleMessages: updatedMessages,
          currentIndex: state.currentIndex + 1,
          clearReplyPreview: true, // ← add this
        ),
      );

      _timer = Timer(
        const Duration(milliseconds: 550),
        _playNext,
      );

      return;
    }

    final character = characters[characterIndex];

    // ---------------------------------------------------------------
    // EMOJI
    // ---------------------------------------------------------------

    if (_isEmoji(character)) {
      emit(
        state.copyWith(
          emojiKeyboardVisible: true,
          keyboardVisible: false,
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
        ),
      );

      _timer = Timer(
        const Duration(milliseconds: 100),
        () {
          if (!state.playing) return;

          emit(
            state.copyWith(
              lastPressedEmoji: character,
              emojiPressCount: state.emojiPressCount + 1,
            ),
          );

          _timer = Timer(
            const Duration(milliseconds: 180),
            () {
              if (!state.playing) return;

              emit(
                state.copyWith(
                  lastPressedEmoji: null,
                ),
              );

              _timer = Timer(
                const Duration(milliseconds: 70),
                () {
                  if (!state.playing) return;

                  typedText += character;

                  // IMPORTANT:
                  // The emoji is now visible in the composer.
                  emit(
                    state.copyWith(
                      composerText: typedText,
                    ),
                  );

                  _typeNextOwnerCharacter(
                    message,
                    characters,
                    characterIndex + 1,
                    typedText,
                  );
                },
              );
            },
          );
        },
      );

      return;
    }

    // ---------------------------------------------------------------
    // NORMAL CHARACTER
    // ---------------------------------------------------------------

    final previousCharacter =
        characterIndex > 0 ? characters[characterIndex - 1] : '';

    final isSentenceStart = characterIndex == 0 ||
        previousCharacter == '.' ||
        previousCharacter == '!' ||
        previousCharacter == '?' ||
        previousCharacter == '\n';

    final isUppercaseMessage =
        message.text.isNotEmpty && message.text == message.text.toUpperCase();

    final shouldShift = isUppercaseMessage || isSentenceStart;

    // Add the character to the text being visibly typed.
    typedText += character;

    final keyToShow = character == ' ' ? 'space' : character;

    // IMPORTANT:
    // composerText is updated here, so the user sees the text
    // appearing character-by-character.
    emit(
      state.copyWith(
        composerText: typedText,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        pressedKey: keyToShow,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftEnabled: shouldShift,
        shiftPressed: false,
      ),
    );

    characterIndex++;

    final delay = _humanCharacterDelay(
      character: character,
      nextCharacter: characterIndex < characters.length
          ? characters[characterIndex]
          : null,
    );

    _timer = Timer(
      delay,
      () {
        _typeNextOwnerCharacter(
          message,
          characters,
          characterIndex,
          typedText,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HUMAN TYPING SPEED
  // ---------------------------------------------------------------------------

  Duration _humanCharacterDelay({
    required String character,
    required String? nextCharacter,
  }) {
    // Base human keyboard interval.
    var milliseconds = 75 + _random.nextInt(120);

    // Spaces usually create a slightly larger pause.
    if (character == ' ') {
      milliseconds += 50 + _random.nextInt(90);
    }

    // Punctuation usually causes a small pause.
    if (character == '.' ||
        character == ',' ||
        character == '!' ||
        character == '?' ||
        character == ':') {
      milliseconds += 100 + _random.nextInt(180);
    }

    // Slight pause after punctuation before the next word.
    if (character == '.' ||
        character == '!' ||
        character == '?' ||
        character == ',') {
      milliseconds += 80 + _random.nextInt(150);
    }

    // Occasional hesitation, like a real person typing.
    if (_random.nextInt(18) == 0) {
      milliseconds += 250 + _random.nextInt(500);
    }

    // Another small pause before punctuation.
    if (nextCharacter == '.' ||
        nextCharacter == ',' ||
        nextCharacter == '!' ||
        nextCharacter == '?') {
      milliseconds += 50 + _random.nextInt(100);
    }

    return Duration(milliseconds: milliseconds);
  }

  // ---------------------------------------------------------------------------
  // HUMAN TYPING DURATION FOR OTHER PARTICIPANTS
  // ---------------------------------------------------------------------------

  Duration _humanTypingDuration(String text) {
    if (text.trim().isEmpty) {
      return const Duration(milliseconds: 800);
    }

    final characters = text.characters.length;

    // Approximate human typing speed:
    //
    // 180-260 characters/minute gives roughly
    // 230-330ms per character.
    //
    // We use a randomized range so every replay doesn't feel identical.

    final basePerCharacter = 210 + _random.nextInt(90); // 210-299 ms

    var milliseconds = characters * basePerCharacter;

    // Minimum typing time.
    milliseconds = max(milliseconds, 1200);

    // Short messages shouldn't feel unnaturally slow.
    if (characters <= 5) {
      milliseconds = 1200 + _random.nextInt(700);
    } else if (characters <= 12) {
      milliseconds = 1800 + _random.nextInt(900);
    } else if (characters <= 25) {
      milliseconds = 2600 + _random.nextInt(1200);
    } else if (characters <= 50) {
      milliseconds = 4000 + _random.nextInt(1600);
    } else if (characters <= 90) {
      milliseconds = 6000 + _random.nextInt(2200);
    } else {
      milliseconds = 8000 + _random.nextInt(3000);
    }

    // Extra time for punctuation and pauses between sentences.
    final punctuationCount = RegExp(r'[.!?,]').allMatches(text).length;

    milliseconds += punctuationCount * 250;

    // Spaces represent word transitions.
    final wordCount = text.trim().split(RegExp(r'\s+')).length;

    milliseconds += wordCount * 60;

    // Occasional longer hesitation.
    if (_random.nextInt(8) == 0) {
      milliseconds += 500 + _random.nextInt(1000);
    }

    return Duration(milliseconds: milliseconds);
  }

  // ---------------------------------------------------------------------------
  // KEYBOARD
  // ---------------------------------------------------------------------------

  void hideKeyboard() {
    emit(
      state.copyWith(
        keyboardVisible: false,
        emojiKeyboardVisible: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMOJI DETECTION
  // ---------------------------------------------------------------------------

  bool _isEmoji(String character) {
    if (character.isEmpty) {
      return false;
    }

    final rune = character.runes.first;

    return (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF);
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
