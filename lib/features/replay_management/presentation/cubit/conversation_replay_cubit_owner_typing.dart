part of 'conversation_replay_cubit.dart';

mixin _OwnerTypingMixin on _ConversationReplayCubitBase {
  @override
  void _typeOwnerMessage(Message message) {
    if (message.replyToMessageId != null && message.replyToText != null) {
      _performSwipeThenType(message);
      return;
    }
    final characters =
        (message.originalText ?? message.text).characters.toList();

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
      // Always show the original text first (even if the message was later deleted)
      final messageToShow = message.isDeleted
          ? message.copyWith(
              text: message.originalText ?? message.text,
              isDeleted: false,
            )
          : message;

      final updatedMessages = List<Message>.from(state.visibleMessages)
        ..add(messageToShow);

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

      if (message.isDeleted) {
        _scheduleDeletion(message);
      }

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
}
