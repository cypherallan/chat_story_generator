import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';

part 'conversation_replay_state.dart';

class ConversationReplayCubit extends Cubit<ConversationReplayState> {
  ConversationReplayCubit() : super(const ConversationReplayState());

  final List<Message> _messages = [];
  final Random _random = Random();

  String _ownerId = "";

  Timer? _timer;

  void load(
    List<Message> messages,
    String ownerId,
  ) {
    _messages
      ..clear()
      ..addAll(messages);

    _ownerId = ownerId;

    emit(const ConversationReplayState());
  }

  void play() {
    if (state.playing || state.finished) return;

    emit(
      state.copyWith(
        playing: true,
        paused: false,
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
    return text.runes.map((rune) => String.fromCharCode(rune)).toList();
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
            keyboardVisible: false,
            emojiKeyboardVisible: false,
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

      // Emoji detected
      if (_isEmoji(character)) {
        currentText += character;
        characterIndex++;

        emit(
          state.copyWith(
            composerText: currentText,
            emojiKeyboardVisible: true,
            keyboardVisible: false,
            pressedEmoji: character,
            pressedKey: null,
          ),
        );

        _timer = Timer(
          const Duration(milliseconds: 350),
          () {
            emit(
              state.copyWith(
                pressedEmoji: null,
              ),
            );

            _timer = Timer(
              _nextTypingDelay(),
              typeNextCharacter,
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
    final code = character.codeUnitAt(0);

    return (code >= 0x1F300 && code <= 0x1FAFF) ||
        (code >= 0x2600 && code <= 0x27BF);
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
    if (text.length < 25) {
      return const Duration(seconds: 2);
    }

    if (text.length < 80) {
      return const Duration(seconds: 3);
    }

    return const Duration(seconds: 5);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
