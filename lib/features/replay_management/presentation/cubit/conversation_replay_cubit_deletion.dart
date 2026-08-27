part of 'conversation_replay_cubit.dart';

mixin _DeletionMixin on _ConversationReplayCubitBase {
  @override
  void _resumeActiveDeletion() {
    if (state.screen != ReplayScreen.conversation) return;
    final messageId = _activeDeletionMessageId;
    if (messageId == null) return;
    Message? originalMessage;
    for (final m in _messages) {
      if (m.id == messageId) {
        originalMessage = m;
        break;
      }
    }
    if (originalMessage == null) return;
    final visible = state.visibleMessages.where((m) => m.id == messageId);
    if (visible.isNotEmpty && visible.first.isDeleted) return;
    _scheduleDeletion(originalMessage);
  }

  void _scheduleDeletion(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) return;
    if (originalMessage.deletedAt == null) return;
    if (state.typing && state.typingPersonId == _ownerId) {
      _waitForTypingToFinish(originalMessage);
      return;
    }
    if (state.composerText.isNotEmpty) {
      _waitForTypingToFinish(originalMessage);
      return;
    }
    final targetDelay =
        originalMessage.deletedAt!.difference(originalMessage.createdAt);
    final effectiveDelay = targetDelay.isNegative ? Duration.zero : targetDelay;
    final alreadyElapsed =
        _deletionElapsed[originalMessage.id] ?? Duration.zero;
    var remaining = effectiveDelay - alreadyElapsed;
    if (remaining <= Duration.zero) {
      _startVisualDeletion(originalMessage);
      return;
    }
    if (state.playing) {
      remaining = _compressRealGap(remaining);
    }
    _deletionTimer?.cancel();
    _activeDeletionMessageId = originalMessage.id;
    _deletionStartedAt = DateTime.now();
    _deletionTimer = Timer(remaining, () {
      _deletionTimer = null;
      if (state.screen != ReplayScreen.conversation) {
        _pauseDeletionTimer();
        return;
      }
      _startVisualDeletion(originalMessage);
    });
  }

  void _waitForTypingToFinish(Message originalMessage) {
    _pauseDeletionTimer();
    _deletionTimer?.cancel();
    _deletionTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (state.screen != ReplayScreen.conversation) {
        timer.cancel();
        _deletionTimer = null;
        return;
      }
      if (state.typing && state.typingPersonId == _ownerId) return;
      if (state.composerText.isNotEmpty) return;
      timer.cancel();
      _deletionTimer = null;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (state.screen != ReplayScreen.conversation) return;
        _scheduleDeletion(originalMessage);
      });
    });
  }

  @override
  void _startVisualDeletion(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) return;

    // PLAYING MODE: show scroll-back -> long-press -> delete icon -> confirm -> delete
    if (state.playing) {
      // 1. scroll-back / long-press select
      emit(state.copyWith(
        selectedMessageIds: {originalMessage.id},
        deleteIconPressed: false,
        showDeleteConfirmation: false,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
      ));

      // 2. delete icon appears
      _deletionTimer?.cancel();
      _deletionTimer = Timer(const Duration(milliseconds: 700), () {
        if (!state.playing || state.screen != ReplayScreen.conversation) return;
        emit(state.copyWith(deleteIconPressed: true));

        // 3. confirmation popup
        _deletionTimer = Timer(const Duration(milliseconds: 500), () {
          if (!state.playing || state.screen != ReplayScreen.conversation)
            return;
          emit(state.copyWith(
              deleteIconPressed: false, showDeleteConfirmation: true));

          // 4. press OK -> actual delete like MessageCubitDeleteMixin
          _deletionTimer = Timer(const Duration(milliseconds: 700), () {
            if (!state.playing || state.screen != ReplayScreen.conversation)
              return;
            deleteMessageForMe(originalMessage);
            _nextDeletionIndex++;
            _timer = Timer(const Duration(milliseconds: 400), _playNext);
          });
        });
      });
      return;
    }

    // NORMAL MODE (not playing) - your existing logic
    _deletionTimer?.cancel();
    _deletionTimer = null;
    _deletionStartedAt = null;
    _activeDeletionMessageId = originalMessage.id;
    emit(state.copyWith(
      selectedMessageIds: {originalMessage.id},
      deleteIconPressed: false,
      keyboardVisible: false,
      emojiKeyboardVisible: false,
    ));
    _deletionTimer = Timer(const Duration(milliseconds: 900), () {
      if (state.screen != ReplayScreen.conversation) return;
      emit(state.copyWith(deleteIconPressed: true));
      _deletionTimer = Timer(const Duration(milliseconds: 450), () {
        if (state.screen != ReplayScreen.conversation) return;
        emit(state.copyWith(
            deleteIconPressed: false, showDeleteConfirmation: true));
      });
    });
  }

  void deleteMessageForMe(Message originalMessage) {
    if (state.screen != ReplayScreen.conversation) return;
    final currentMessages = List<Message>.from(state.visibleMessages);
    final index = currentMessages.indexWhere((m) => m.id == originalMessage.id);
    if (index == -1) return;
    final currentMessage = currentMessages[index];
    final deletedMessage = currentMessage.copyWith(
      originalText: currentMessage.originalText ??
          originalMessage.originalText ??
          originalMessage.text,
      text: 'This message was deleted',
      isDeleted: true,
      imagePath: null,
      replyToMessageId: null,
      replyToSenderId: null,
      replyToSenderName: null,
      replyToText: null,
    );
    currentMessages[index] = deletedMessage;
    emit(state.copyWith(
      visibleMessages: currentMessages,
      clearSelection: true,
      deleteIconPressed: false,
      showDeleteConfirmation: false,
    ));
    _deletionElapsed.remove(originalMessage.id);
    _activeDeletionMessageId = null;
    _deletionStartedAt = null;
  }

  void cancelDeleteConfirmation() {
    if (state.screen != ReplayScreen.conversation) return;
    emit(state.copyWith(
        showDeleteConfirmation: false, deleteIconPressed: false));
  }
}
