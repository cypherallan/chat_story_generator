import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../message_management/domain/entities/message.dart';

import 'package:characters/characters.dart';

import 'conversation_replay_state.dart';

class ConversationReplayCubit extends Cubit<ConversationReplayState> {
  ConversationReplayCubit() : super(const ConversationReplayState());
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
      ),
    );
  }

  void goBackToHome() {
    showHome();
  }

  final List<Message> _messages = [];
  final Random _random = Random();

  String _ownerId = "";
  String get ownerId => _ownerId;

  Timer? _timer;

  void load(
    List<Message> messages,
    String ownerId,
  ) {
    _messages
      ..clear()
      ..addAll(messages);

    _ownerId = ownerId;

    final Set<String> emojiSet = {};
    for (final message in messages) {
      for (final char in message.text.characters) {
        if (_isEmoji(char)) {
          emojiSet.add(char);
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

  void play() {
    if (state.playing || state.finished) return;

    emit(
      state.copyWith(
        playing: true,
        paused: false,
        keyboardVisible: true,
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

  void _playNext() {
    if (!state.playing) return;

    if (state.currentIndex >= _messages.length) {
      emit(
        state.copyWith(
          playing: false,
          finished: true,
          typing: false,
        ),
      );
      return;
    }

    final message = _messages[state.currentIndex];

    if (message.senderId == _ownerId) {
      _typeOwnerMessage(message);
      return;
    }

    emit(
      state.copyWith(
        typing: true,
        typingPersonId: message.senderId,
        onlinePersonId: message.senderId,
      ),
    );

    _timer = Timer(
      _typingDelay(message.text),
      () {
        final updated = List<Message>.from(state.visibleMessages)..add(message);

        emit(
          state.copyWith(
            typing: false,
            visibleMessages: updated,
            currentIndex: state.currentIndex + 1,
          ),
        );

        _timer = Timer(
          const Duration(milliseconds: 700),
          _playNext,
        );
      },
    );
  }

  List<String> _characters(String text) {
    return text.characters.toList();
  }

  void hideKeyboard() {
    emit(
      state.copyWith(
        keyboardVisible: false,
        emojiKeyboardVisible: false,
      ),
    );
  }

  void _typeOwnerMessage(Message message) {
    String currentText = '';

    emit(
      state.copyWith(
        composerText: '',
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        shiftEnabled: true,
        shiftPressed: true,
      ),
    );

    _timer = Timer(
      const Duration(milliseconds: 120),
      () {
        emit(
          state.copyWith(
            shiftPressed: false,
          ),
        );
      },
    );

    final characters = _characters(message.text);

    int characterIndex = 0;

    void typeNextCharacter() {
      if (!state.playing) {
        return;
      }

      if (characterIndex >= characters.length) {
        final updated = List<Message>.from(state.visibleMessages)..add(message);

        emit(
          state.copyWith(
            composerText: '',
            pressedKey: null,
            pressedEmoji: null,
            shiftPressed: false,
            visibleMessages: updated,
            currentIndex: state.currentIndex + 1,
          ),
        );

        _timer = Timer(
          const Duration(milliseconds: 500),
          _playNext,
        );

        return;
      }

      final character = characters[characterIndex];

      if (_isEmoji(character)) {
        characterIndex++;

        // Open emoji keyboard
        emit(
          state.copyWith(
            emojiKeyboardVisible: true,
            keyboardVisible: false,
            pressedKey: null,
            lastPressedEmoji: null,
          ),
        );

        // Finger DOWN immediately
        _timer = Timer(
          const Duration(milliseconds: 60),
          () {
            emit(
              state.copyWith(
                lastPressedEmoji: character,
                emojiPressCount: state.emojiPressCount + 1,
              ),
            );

            // Hold — long enough to see the flash
            _timer = Timer(
              const Duration(milliseconds: 180),
              () {
                // Finger UP
                emit(
                  state.copyWith(
                    lastPressedEmoji: null,
                  ),
                );

                // Insert emoji
                _timer = Timer(
                  const Duration(milliseconds: 50),
                  () {
                    currentText += character;

                    emit(
                      state.copyWith(
                        composerText: currentText,
                      ),
                    );

                    _timer = Timer(
                      _nextTypingDelay(),
                      typeNextCharacter,
                    );
                  },
                );
              },
            );
          },
        );

        return;
      }

      final previousCharacter =
          characterIndex > 0 ? characters[characterIndex - 1] : '';

      final isSentenceStart = characterIndex == 0 ||
          previousCharacter == '.' ||
          previousCharacter == '!' ||
          previousCharacter == '?';

      final isUppercaseMessage = message.text == message.text.toUpperCase();

      final shouldShift = isUppercaseMessage || isSentenceStart;

      currentText += character;
      characterIndex++;

      emit(
        state.copyWith(
          composerText: currentText,
          keyboardVisible: true,
          emojiKeyboardVisible: false,
          pressedKey: character,
          pressedEmoji: null,
          shiftEnabled: shouldShift,
          shiftPressed: false,
        ),
      );

      _timer = Timer(
        _nextTypingDelay(),
        typeNextCharacter,
      );
    }

    typeNextCharacter();
  }

  bool _isEmoji(String character) {
    final rune = character.runes.first;

    return (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF);
  }

  Duration _nextTypingDelay() {
    final delay = 140 + _random.nextInt(180);

    if (_random.nextInt(15) == 0) {
      return Duration(
        milliseconds: delay + 400,
      );
    }

    return Duration(
      milliseconds: delay,
    );
  }

  Duration _typingDelay(String text) {
    // Count actual characters rather than using broad fixed buckets.
    final characterCount = text.characters.length;

    // Humans don't type at a perfectly constant speed.
    // This gives an average base speed of roughly 5–7 characters/second.
    final baseMilliseconds = characterCount * 155;

    // Small natural variation for every message.
    final variation = _random.nextInt(700) - 350;

    // Extra thinking/pause time for punctuation.
    final punctuationCount = RegExp(r'[,.!?;:]').allMatches(text).length;
    final punctuationPause = punctuationCount * 180;

    // Slight pauses for longer messages.
    final longMessagePause = characterCount > 45 ? _random.nextInt(1000) : 0;

    var milliseconds =
        baseMilliseconds + variation + punctuationPause + longMessagePause;

    // Never let even a very short message appear instantly.
    milliseconds = max(milliseconds, 1200);

    // Keep extremely long messages from becoming ridiculously slow.
    milliseconds = min(milliseconds, 12000);

    return Duration(milliseconds: milliseconds);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
