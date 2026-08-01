import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';

part 'conversation_replay_state.dart';

class ConversationReplayCubit extends Cubit<ConversationReplayState> {
  ConversationReplayCubit() : super(const ConversationReplayState());

  final List<Message> _messages = [];

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

    // OWNER messages will be handled next stage.
    // OWNER is typing into the composer.
    if (message.senderId == _ownerId) {
      _typeOwnerMessage(message);
      return;
    }

    // OTHER PERSON starts typing.
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

  void _typeOwnerMessage(Message message) {
    String currentText = '';

    emit(
      state.copyWith(
        composerText: '',
        keyboardVisible: true,
        shiftEnabled: true,
        pressedKey: "⇧",
      ),
    );

    int characterIndex = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 130), (timer) {
      if (!state.playing) {
        timer.cancel();
        return;
      }

      if (characterIndex >= message.text.length) {
        timer.cancel();

        final updated = List<Message>.from(state.visibleMessages)..add(message);

        emit(
          state.copyWith(
            composerText: '',
            keyboardVisible: false,
            pressedKey: null,
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

      final character = message.text[characterIndex];

      final previousCharacter =
          characterIndex > 0 ? message.text[characterIndex - 1] : '';

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
          pressedKey: character,
          shiftEnabled: shouldShift,
        ),
      );
    });
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
