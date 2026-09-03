part of 'conversation_replay_cubit.dart';

mixin _OwnerTypingMixin on _ConversationReplayCubitBase {
  @override
  void _typeOwnerMessage(Message message) {
    if (message.replyToMessageId != null && message.replyToText != null) {
      _performSwipeThenType(message);
      return;
    }

    if (message.typingEvents.isEmpty) {
      _startOwnerTyping(message);
      return;
    }

    _startRecordedOwnerTyping(message);
  }

  @override
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

  void _startRecordedOwnerTyping(Message message) {
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

        _typeNextRecordedEvent(
          message,
          0,
          '',
        );
      },
    );
  }

  void _typeNextRecordedEvent(
    Message message,
    int eventIndex,
    String currentText,
  ) {
    if (!state.playing) return;

    final events = message.typingEvents;

    if (state.pressedKey != null ||
        state.pressedEmoji != null ||
        state.lastPressedEmoji != null) {
      emit(
        state.copyWith(
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
        ),
      );
    }

    if (eventIndex >= events.length) {
      final messageToShow = message.isDeleted
          ? message.copyWith(
              text: message.originalText ?? message.text,
              isDeleted: false,
            )
          : message;

      final updatedMessages = List<Message>.from(state.visibleMessages)
        ..add(messageToShow);

      _visiblePerProject[message.projectId] =
          List<Message>.from(updatedMessages);

      soundService.playSend();

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
          clearReplyPreview: true,
        ),
      );

      _timer = Timer(
        const Duration(milliseconds: 550),
        _playNext,
      );

      return;
    }

    final event = events[eventIndex];

    final delay = Duration(milliseconds: event.delayMs);

    _timer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () {
        if (!state.playing) return;

        var updatedText = currentText;

        if (event.type == 'delete') {
          final start = event.position.clamp(0, updatedText.length);
          final end = (start + (event.text?.length ?? 0))
              .clamp(start, updatedText.length);

          updatedText = updatedText.replaceRange(start, end, '');

          emit(
            state.copyWith(
              composerText: updatedText,
              keyboardVisible: true,
              emojiKeyboardVisible: false,
              pressedKey: 'backspace',
              pressedEmoji: null,
              lastPressedEmoji: null,
            ),
          );

          _timer = Timer(
            const Duration(milliseconds: 30),
            () {
              if (!state.playing) return;

              emit(
                state.copyWith(
                  pressedKey: null,
                ),
              );

              _typeNextRecordedEvent(
                message,
                eventIndex + 1,
                updatedText,
              );
            },
          );

          return;
        }

        if (event.type == 'insert') {
          final insertedText = event.text ?? '';
          final position = event.position.clamp(0, updatedText.length);

          updatedText = updatedText.replaceRange(
            position,
            position,
            insertedText,
          );

          final insertedCharacters = insertedText.characters.toList();

          final lastCharacter =
              insertedCharacters.isNotEmpty ? insertedCharacters.last : '';

          if (_isEmoji(lastCharacter)) {
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
                    lastPressedEmoji: lastCharacter,
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

                        emit(
                          state.copyWith(
                            composerText: updatedText,
                          ),
                        );

                        _typeNextRecordedEvent(
                          message,
                          eventIndex + 1,
                          updatedText,
                        );
                      },
                    );
                  },
                );
              },
            );

            return;
          }

          final keyToShow = lastCharacter == ' ' ? 'space' : lastCharacter;

          emit(
            state.copyWith(
              composerText: updatedText,
              keyboardVisible: true,
              emojiKeyboardVisible: false,
              pressedKey: keyToShow,
              pressedEmoji: null,
              lastPressedEmoji: null,
              shiftEnabled: lastCharacter.isNotEmpty &&
                  lastCharacter == lastCharacter.toUpperCase() &&
                  lastCharacter != lastCharacter.toLowerCase(),
              shiftPressed: false,
            ),
          );

          _timer = Timer(
            const Duration(milliseconds: 30),
            () {
              if (!state.playing) return;

              emit(
                state.copyWith(
                  pressedKey: null,
                ),
              );

              _typeNextRecordedEvent(
                message,
                eventIndex + 1,
                updatedText,
              );
            },
          );

          return;
        }

        _typeNextRecordedEvent(
          message,
          eventIndex + 1,
          updatedText,
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

    if (characterIndex >= characters.length) {
      final messageToShow = message.isDeleted
          ? message.copyWith(
              text: message.originalText ?? message.text,
              isDeleted: false,
            )
          : message;

      final updatedMessages = List<Message>.from(state.visibleMessages)
        ..add(messageToShow);

      _visiblePerProject[message.projectId] =
          List<Message>.from(updatedMessages);

      // SOUND: sent
      soundService.playSend();

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
          clearReplyPreview: true,
        ),
      );

      _timer = Timer(
        const Duration(milliseconds: 550),
        _playNext,
      );

      return;
    }

    final character = characters[characterIndex];

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

    typedText += character;

    final keyToShow = character == ' ' ? 'space' : character;
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

    const keyPressDuration = Duration(milliseconds: 30);

    _timer = Timer(
      keyPressDuration,
      () {
        if (!state.playing) return;

        emit(
          state.copyWith(
            pressedKey: null,
          ),
        );

        final remainingDelay = delay - keyPressDuration;

        _timer = Timer(
          remainingDelay.isNegative ? Duration.zero : remainingDelay,
          () {
            if (!state.playing) return;

            _typeNextOwnerCharacter(
              message,
              characters,
              characterIndex,
              typedText,
            );
          },
        );
      },
    );
  }
}
