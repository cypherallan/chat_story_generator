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

    // Find the original message.
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

    // If the message has already been visually deleted, there is nothing
    // left to resume.
    final visibleMessage = state.visibleMessages.where(
      (message) => message.id == messageId,
    );

    if (visibleMessage.isNotEmpty && visibleMessage.first.isDeleted) {
      return;
    }

    // Continue the deletion countdown.
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

    // ---------------------------------------------------------------------------
    // DO NOT START / RESUME DELETION WHILE OWNER IS TYPING
    // ---------------------------------------------------------------------------
    //
    // The owner is "me" in the replay.
    //
    // Deletion is frozen while the owner is typing because the replay can only
    // perform one visible action at a time.
    //

    final ownerIsTyping = state.typing && state.typingPersonId == _ownerId;

    final ownerHasComposerText = state.composerText.isNotEmpty;

    if (ownerIsTyping || ownerHasComposerText) {
      _waitForTypingToFinish(originalMessage);
      return;
    }

    // ---------------------------------------------------------------------------
    // CALCULATE ORIGINAL DELETION DELAY
    // ---------------------------------------------------------------------------

    final targetDelay =
        originalMessage.deletedAt!.difference(originalMessage.createdAt);

    final effectiveDelay = targetDelay.isNegative ? Duration.zero : targetDelay;

    final messageId = originalMessage.id;

    // This contains ONLY active conversation time.
    //
    // Time spent on the home screen is never added here because
    // _pauseDeletionTimer() is called when leaving the conversation.
    final alreadyElapsed = _deletionElapsed[messageId] ?? Duration.zero;

    final remaining = effectiveDelay - alreadyElapsed;

    // ---------------------------------------------------------------------------
    // DELETION TIME HAS ALREADY BEEN REACHED
    // ---------------------------------------------------------------------------

    if (remaining <= Duration.zero) {
      _startVisualDeletion(originalMessage);
      return;
    }

    // ---------------------------------------------------------------------------
    // START / RESUME COUNTDOWN
    // ---------------------------------------------------------------------------

    _deletionTimer?.cancel();

    _activeDeletionMessageId = messageId;
    _deletionStartedAt = DateTime.now();

    _deletionTimer = Timer(
      remaining,
      () {
        _deletionTimer = null;

        // If we left the conversation, freeze the timer.
        if (state.screen != ReplayScreen.conversation) {
          _pauseDeletionTimer();
          return;
        }

        // Owner started typing while the countdown was running.
        if (state.typing && state.typingPersonId == _ownerId) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        // Composer contains text, so another action is currently taking place.
        if (state.composerText.isNotEmpty) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        // Safe to perform the deletion sequence.
        _startVisualDeletion(originalMessage);
      },
    );
  }

  // ===========================================================================
  // WAIT UNTIL OWNER FINISHES TYPING
  // ===========================================================================

  void _waitForTypingToFinish(Message originalMessage) {
    // ---------------------------------------------------------------------------
    // FREEZE ACTIVE DELETION TIME
    // ---------------------------------------------------------------------------
    //
    // This is important.
    //
    // Once the owner starts typing, the deletion countdown stops completely.
    // The time spent typing is NOT counted toward deletedAt - createdAt.
    //

    _pauseDeletionTimer();

    _deletionTimer?.cancel();

    _deletionTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (timer) {
        // -----------------------------------------------------------------------
        // USER LEFT THE CONVERSATION
        // -----------------------------------------------------------------------

        if (state.screen != ReplayScreen.conversation) {
          timer.cancel();
          _deletionTimer = null;
          return;
        }

        // -----------------------------------------------------------------------
        // OWNER STILL TYPING
        // -----------------------------------------------------------------------

        final ownerIsTyping = state.typing && state.typingPersonId == _ownerId;

        if (ownerIsTyping) {
          return;
        }

        // -----------------------------------------------------------------------
        // COMPOSER STILL HAS CONTENT
        // -----------------------------------------------------------------------

        if (state.composerText.isNotEmpty) {
          return;
        }

        // -----------------------------------------------------------------------
        // OWNER FINISHED THE ACTION
        // -----------------------------------------------------------------------

        timer.cancel();
        _deletionTimer = null;

        // Give the UI one frame to settle before restarting the deletion
        // countdown.
        //
        // This prevents typing completion and deletion from visually happening
        // in the same frame.
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

    // Never begin the visual deletion sequence while the owner is typing.
    final ownerIsTyping = state.typing && state.typingPersonId == _ownerId;

    if (ownerIsTyping || state.composerText.isNotEmpty) {
      _waitForTypingToFinish(originalMessage);
      return;
    }

    // The deletion countdown is finished.
    _deletionTimer?.cancel();
    _deletionTimer = null;

    _deletionStartedAt = null;
    _activeDeletionMessageId = originalMessage.id;

    // ---------------------------------------------------------------------------
    // STEP 1 — LONG PRESS
    // ---------------------------------------------------------------------------

    // The deletion countdown is finished.
    _deletionTimer?.cancel();
    _deletionTimer = null;

    _deletionStartedAt = null;
    _activeDeletionMessageId = originalMessage.id;

    // -------------------------------------------------------------------------
    // STEP 1 — LONG PRESS
    // -------------------------------------------------------------------------
    //
    // This causes the selection header to appear.
    //

    emit(
      state.copyWith(
        selectedMessageIds: {originalMessage.id},
        deleteIconPressed: false,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
      ),
    );

    // -------------------------------------------------------------------------
    // STEP 2 — LET THE USER SEE THE LONG-PRESS RESULT
    // -------------------------------------------------------------------------

    _deletionTimer = Timer(
      const Duration(milliseconds: 900),
      () {
        if (state.screen != ReplayScreen.conversation) {
          return;
        }

        // Never perform the next action while owner is typing.
        if (state.typing && state.typingPersonId == _ownerId) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        if (state.composerText.isNotEmpty) {
          _waitForTypingToFinish(originalMessage);
          return;
        }

        // ---------------------------------------------------------------------
        // STEP 3 — TAP DELETE ICON
        // ---------------------------------------------------------------------

        emit(
          state.copyWith(
            deleteIconPressed: true,
          ),
        );

        // ---------------------------------------------------------------------
        // STEP 4 — SHOW DELETE CONFIRMATION
        // ---------------------------------------------------------------------

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

  // ===========================================================================
  // DELETE CONFIRMATION
  // ===========================================================================

  void _showDeleteConfirmation(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) {
      return;
    }

    // The delete icon has finished its visual tap.
    //
    // Tell the ReplayConversationView to display the real Flutter
    // confirmation dialog.
    emit(
      state.copyWith(
        deleteIconPressed: false,
        showDeleteConfirmation: true,
      ),
    );
  }

  // ===========================================================================
  // APPLY DELETE FOR ME
  // ===========================================================================

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
