part of 'conversation_replay_cubit.dart';

mixin _DeletionMixin on _ConversationReplayCubitBase {
  @override
  void _resumeActiveDeletion() {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }

    final messageId = _activeDeletionMessageId;

    if (messageId == null) {
      return;
    }

    Message? originalMessage;

    for (final message in _messages) {
      if (message.id == messageId) {
        originalMessage = message;
        break;
      }
    }

    if (originalMessage == null) {
      return;
    }
    final visibleMessage = state.visibleMessages.where(
      (message) => message.id == messageId,
    );

    if (visibleMessage.isNotEmpty && visibleMessage.first.isDeleted) {
      return;
    }
    _scheduleDeletion(originalMessage);
  }

  @override
  void _scheduleDeletion(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }

    if (originalMessage.deletedAt == null) {
      return;
    }

    final ownerIsTyping = state.typing && state.typingPersonId == _ownerId;

    final ownerHasComposerText = state.composerText.isNotEmpty;

    if (ownerIsTyping || ownerHasComposerText) {
      _waitForTypingToFinish(originalMessage);
      return;
    }

    final targetDelay =
        originalMessage.deletedAt!.difference(originalMessage.createdAt);

    final effectiveDelay = targetDelay.isNegative ? Duration.zero : targetDelay;

    final messageId = originalMessage.id;
    final alreadyElapsed = _deletionElapsed[messageId] ?? Duration.zero;

    final remaining = effectiveDelay - alreadyElapsed;

    if (remaining <= Duration.zero) {
      _startVisualDeletion(originalMessage);
      return;
    }

    _deletionTimer?.cancel();

    _activeDeletionMessageId = messageId;
    _deletionStartedAt = DateTime.now();

    _deletionTimer = Timer(
      remaining,
      () {
        _deletionTimer = null;

        if (state.screen != ReplayScreen.conversation) {
          _pauseDeletionTimer();
          return;
        }
        if (state.typing && state.typingPersonId == _ownerId) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        if (state.composerText.isNotEmpty) {
          _waitForTypingToFinish(originalMessage);
          return;
        }
        _startVisualDeletion(originalMessage);
      },
    );
  }

  void _waitForTypingToFinish(Message originalMessage) {
    _pauseDeletionTimer();

    _deletionTimer?.cancel();

    _deletionTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (timer) {
        if (state.screen != ReplayScreen.conversation) {
          timer.cancel();
          _deletionTimer = null;
          return;
        }

        final ownerIsTyping = state.typing && state.typingPersonId == _ownerId;

        if (ownerIsTyping) {
          return;
        }

        if (state.composerText.isNotEmpty) {
          return;
        }

        timer.cancel();
        _deletionTimer = null;
        Future<void>.delayed(
          const Duration(milliseconds: 50),
          () {
            if (state.screen != ReplayScreen.conversation) {
              return;
            }

            _scheduleDeletion(originalMessage);
          },
        );
      },
    );
  }

  void _startVisualDeletion(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }

    final ownerIsTyping = state.typing && state.typingPersonId == _ownerId;

    if (ownerIsTyping || state.composerText.isNotEmpty) {
      _waitForTypingToFinish(originalMessage);
      return;
    }

    _deletionTimer?.cancel();
    _deletionTimer = null;

    _deletionStartedAt = null;
    _activeDeletionMessageId = originalMessage.id;
    _deletionTimer?.cancel();
    _deletionTimer = null;

    _deletionStartedAt = null;
    _activeDeletionMessageId = originalMessage.id;

    emit(
      state.copyWith(
        selectedMessageIds: {originalMessage.id},
        deleteIconPressed: false,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
      ),
    );

    _deletionTimer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (state.screen != ReplayScreen.conversation) {
          return;
        }

        if (state.typing && state.typingPersonId == _ownerId) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        if (state.composerText.isNotEmpty) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        emit(
          state.copyWith(
            deleteIconPressed: true,
          ),
        );

        _deletionTimer = Timer(
          const Duration(milliseconds: 450),
          () {
            if (state.screen != ReplayScreen.conversation) {
              return;
            }

            _showDeleteConfirmation(originalMessage);
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }
    emit(
      state.copyWith(
        deleteIconPressed: false,
        showDeleteConfirmation: true,
      ),
    );
  }

  void deleteMessageForMe(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }

    final currentMessages = List<Message>.from(state.visibleMessages);

    final index = currentMessages.indexWhere(
      (message) => message.id == originalMessage.id,
    );

    if (index == -1) {
      return;
    }

    final currentMessage = currentMessages[index];

    final deletedMessage = currentMessage.copyWith(
      text: 'This message was deleted',
      isDeleted: true,
      imagePath: null,
      replyToMessageId: null,
      replyToSenderId: null,
      replyToSenderName: null,
      replyToText: null,
    );

    currentMessages[index] = deletedMessage;

    emit(
      state.copyWith(
        visibleMessages: currentMessages,
        clearSelection: true,
        deleteIconPressed: false,
        showDeleteConfirmation: false,
      ),
    );

    _deletionElapsed.remove(originalMessage.id);
    _activeDeletionMessageId = null;
    _deletionStartedAt = null;
  }

  void cancelDeleteConfirmation() {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }

    emit(
      state.copyWith(
        showDeleteConfirmation: false,
        deleteIconPressed: false,
      ),
    );
  }
}
