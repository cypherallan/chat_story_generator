part of 'conversation_replay_cubit.dart';

mixin _NavigationMixin on _ConversationReplayCubitBase {
  void showHome() {
    _pauseDeletionTimer();

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
        clearHighlightedChat: true,
      ),
    );
  }

  void openConversationViaHome(String projectId) {
    _pauseDeletionTimer();
    _timer?.cancel();

    // only messages of THIS project before start index
    final filtered = _visiblePerProject[projectId] ??
        _messages
            .take(_replayStartIndex)
            .where((m) => m.projectId == projectId)
            .toList();

    emit(state.copyWith(
      screen: ReplayScreen.home,
      highlightedChatProjectId: projectId,
      visualInteraction: ReplayVisualInteraction.chatTap,
      currentProjectId: null,
    ));

    _timer = Timer(const Duration(milliseconds: 380), () {
      if (isClosed) return;
      emit(state.copyWith(visualInteraction: ReplayVisualInteraction.none));
      emit(state.copyWith(
        screen: ReplayScreen.conversation,
        currentProjectId: projectId,
        visibleMessages: filtered,
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
      ));
      _resumeActiveDeletion();
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (isClosed) return;
        emit(state.copyWith(clearHighlightedChat: true));
      });
    });
  }

  Duration _compressRealGap(Duration real) {
    final seconds = real.inMilliseconds / 1000.0;
    if (seconds <= 0) return const Duration(milliseconds: 800);
    final compressedSeconds = 0.8 + (log(seconds + 1) * 1.2);
    final capped = compressedSeconds.clamp(0.8, 6.0);
    return Duration(milliseconds: (capped * 1000).round());
  }

  void handleReplayNotificationBack() {
    final originalProjectId =
        _messages.isNotEmpty ? _messages.first.projectId : null;

    if (originalProjectId == null) {
      return;
    }

    final returnIndex = _replayNotificationMessageCount ?? state.currentIndex;

    final restoredMessages = _messages.take(returnIndex).toList();

    emit(
      state.copyWith(
        screen: ReplayScreen.conversation,
        currentProjectId: originalProjectId,
        visibleMessages: restoredMessages,
        currentIndex: returnIndex,
        playing: true,
        paused: false,
        finished: false,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        composerText: '',
        replayNotification: null,
      ),
    );

    _playNext();
  }

  void openConversation(String projectId) {
    _pauseDeletionTimer();

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

    _resumeActiveDeletion();
  }

  Future<void> openConversationFromNotification({
    required String projectId,
    String? notificationMessageId, // ← NEW optional parameter
  }) async {
    _pauseDeletionTimer();
    _timer?.cancel();

    // Save the A/B replay state.
    _returnMessages
      ..clear()
      ..addAll(_messages);

    _returnProjectId = state.currentProjectId;
    _returnMessageIndex = state.currentIndex;
    _returnNotificationMessageCount = _replayNotificationMessageCount;

    final result = await getMessages(projectId).first;

    result.fold((failure) {
      emit(
        state.copyWith(
          screen: ReplayScreen.conversation,
          currentProjectId: projectId,
          visibleMessages: const [],
          currentIndex: 0,
          playing: false,
          paused: true,
          finished: true,
        ),
      );
    }, (messages) {
      _messages
        ..clear()
        ..addAll(messages);

      // ---------- Determine start index from the specific notification ----------
      var replyStartIndex = 0;

      final messageIdToFind = notificationMessageId ??
          notificationCubit.currentNotification?.messageId;

      if (messageIdToFind != null) {
        final notificationIndex = _messages.indexWhere(
          (message) => message.id == messageIdToFind,
        );

        if (notificationIndex != -1) {
          replyStartIndex = notificationIndex + 1;
        }
      }
      // ------------------------------------------------------------------------

      // ---------- NEW: also determine an END index (the reply) ----------
      // We look for the first message sent by the owner AFTER the notification.
      // That is the reply the user typed during this visit.
      int endIndex = _messages.length; // fallback = play everything

      for (int i = replyStartIndex; i < _messages.length; i++) {
        if (_messages[i].senderId == _ownerId) {
          endIndex = i + 1; // include the reply, then stop
          break;
        }
      }
      // -----------------------------------------------------------------

      _replayStartIndex = replyStartIndex;
      _replayNotificationMessageCount = null;

      // Tell the playback engine to stop at endIndex and then return
      // We reuse the existing return machinery by temporarily limiting the list
      final messagesForThisVisit = _messages.take(endIndex).toList();

      // Keep the full list in _returnMessages so we can restore later if needed,
      // but for this visit we only want up to the reply.
      _messages
        ..clear()
        ..addAll(messagesForThisVisit);

      final messagesBeforeReply = _messages.take(replyStartIndex).toList();

      emit(
        state.copyWith(
          screen: ReplayScreen.conversation,
          currentProjectId: projectId,
          clearReplayNotification: true,
          visibleMessages: messagesBeforeReply,
          currentIndex: replyStartIndex,
          playing: true,
          paused: false,
          finished: false,
          typing: false,
          typingPersonId: null,
          onlinePersonId: null,
          keyboardVisible: true,
          emojiKeyboardVisible: false,
          composerText: '',
          pressedKey: null,
          pressedEmoji: null,
          shiftPressed: false,
        ),
      );

      _playNext();
    });
  }

  void returnFromNotificationConversation() {
    _timer?.cancel();
    if (_returnMessages.isEmpty || _returnProjectId == null) return;

    final projectId = _returnProjectId!;
    final returnIndex = _returnMessageIndex;
    final lastAcMessage = _messages.isNotEmpty ? _messages.last : null;

    Duration realGap = const Duration(seconds: 2);
    try {
      if (lastAcMessage != null && _returnMessages.length > returnIndex) {
        final nextAb = _returnMessages.firstWhere(
          (m) =>
              m.projectId == projectId &&
              m.createdAt.isAfter(lastAcMessage.createdAt),
          orElse: () => _returnMessages[returnIndex],
        );
        realGap = nextAb.createdAt.difference(lastAcMessage.createdAt);
      }
      final match = notificationCubit.recordedEvents.lastWhere(
        (e) => e.notification.projectId == state.currentProjectId,
      );
      if (match.returnDelayMs != null)
        realGap = Duration(milliseconds: match.returnDelayMs!);
    } catch (_) {}

    final compressed = _compressRealGap(realGap);

    // Find next AB index in the combined list after the AC block
    int nextIndex = returnIndex;
    if (lastAcMessage != null) {
      final idx = _returnMessages.indexWhere(
        (m) =>
            m.projectId == projectId &&
            m.createdAt.isAfter(lastAcMessage.createdAt),
      );
      if (idx != -1) nextIndex = idx;
    }

    _messages
      ..clear()
      ..addAll(_returnMessages);
    _returnMessages.clear();
    _replayNotificationMessageCount = _returnNotificationMessageCount;
    _returnNotificationMessageCount = null;
    _returnProjectId = null;
    _replayStartIndex = nextIndex;

    emit(state.copyWith(
      visualInteraction: ReplayVisualInteraction.backTap,
      playing: false,
      paused: true,
    ));

    _timer = Timer(const Duration(milliseconds: 380), () {
      if (isClosed) return;
      emit(state.copyWith(
        visualInteraction: ReplayVisualInteraction.none,
        screen: ReplayScreen.home,
        highlightedChatProjectId: projectId,
        currentProjectId: null,
        visibleMessages: const [],
      ));
      _timer = Timer(const Duration(milliseconds: 350), () {
        if (isClosed) return;
        emit(
            state.copyWith(visualInteraction: ReplayVisualInteraction.chatTap));
        _timer = Timer(const Duration(milliseconds: 380), () {
          if (isClosed) return;
          emit(state.copyWith(
            screen: ReplayScreen.conversation,
            currentProjectId: projectId,
            visualInteraction: ReplayVisualInteraction.none,
            clearHighlightedChat: true,
            visibleMessages: _visiblePerProject[projectId] ??
                _messages
                    .take(nextIndex)
                    .where((m) => m.projectId == projectId)
                    .toList(),
            currentIndex: nextIndex,
            playing: false,
            paused: true,
            finished: false,
            typing: false,
            typingPersonId: null,
            onlinePersonId: null,
            keyboardVisible: true,
            emojiKeyboardVisible: false,
            composerText: '',
            pressedKey: null,
            pressedEmoji: null,
            shiftPressed: false,
            replayNotification: null,
          ));
          _timer = Timer(compressed, () {
            if (isClosed) return;
            emit(state.copyWith(playing: true, paused: false));
            _playNext();
          });
        });
      });
    });
  }

  void goBackToHome() {
    if (state.screen == ReplayScreen.conversation &&
        state.currentProjectId != null &&
        state.paused) {
      final originalProjectId =
          _messages.isNotEmpty ? _messages.first.projectId : null;

      if (originalProjectId != null &&
          originalProjectId != state.currentProjectId) {
        _timer?.cancel();
        notificationCubit.clear();

        Duration realDelay = const Duration(seconds: 2);
        try {
          final match = notificationCubit.recordedEvents.lastWhere(
            (e) => e.notification.projectId == state.currentProjectId,
          );
          if (match.returnDelayMs != null) {
            realDelay = Duration(milliseconds: match.returnDelayMs!);
          }
        } catch (_) {}
        final compressed = _compressRealGap(realDelay);

        emit(state.copyWith(
          visualInteraction: ReplayVisualInteraction.backTap,
        ));

        _timer = Timer(const Duration(milliseconds: 380), () {
          if (isClosed) return;
          emit(state.copyWith(
            visualInteraction: ReplayVisualInteraction.none,
            screen: ReplayScreen.conversation,
            currentProjectId: originalProjectId,
            visibleMessages: _messages,
            playing: false,
            paused: true,
            finished: false,
            replayNotification: null,
          ));
          _timer = Timer(compressed, () {
            if (isClosed) return;
            emit(state.copyWith(playing: true, paused: false));
            _playNext();
          });
        });
        return;
      }
    }

    _timer?.cancel();
    emit(state.copyWith(visualInteraction: ReplayVisualInteraction.backTap));
    _timer = Timer(const Duration(milliseconds: 380), () {
      if (isClosed) return;
      showHome();
    });
  }

  void setReplayStartTime(DateTime startTime) {
    final availableStart = state.availableStartTime;
    final availableEnd = state.availableEndTime;

    if (availableStart == null || availableEnd == null) {
      return;
    }

    var selectedTime = startTime;

    if (selectedTime.isBefore(availableStart)) {
      selectedTime = availableStart;
    }

    if (selectedTime.isAfter(availableEnd)) {
      selectedTime = availableEnd;
    }

    final previousMessages = _messages
        .where(
          (message) => message.createdAt.isBefore(selectedTime),
        )
        .toList();

    var firstReplayIndex = _messages.indexWhere(
      (message) => !message.createdAt.isBefore(selectedTime),
    );

    if (firstReplayIndex == -1) {
      firstReplayIndex = _messages.length;
    }

    emit(
      state.copyWith(
        replayStartMethod: ReplayStartMethod.time,
        replayStartMessageId: null,
        replayStartTime: selectedTime,
        visibleMessages: previousMessages,
        currentIndex: firstReplayIndex,
        playing: false,
        paused: false,
        finished: false,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
      ),
    );
  }

  void setReplayStartMessage(String messageId) {
    final index = _messages.indexWhere(
      (message) => message.id == messageId,
    );

    if (index == -1) {
      return;
    }

    final selectedMessage = _messages[index];
    _replayStartIndex = index + 1;

    final loadedMessages = _messages.take(index + 1).toList();

    emit(
      state.copyWith(
        replayStartMethod: ReplayStartMethod.message,
        replayStartMessageId: selectedMessage.id,
        replayStartTime: selectedMessage.createdAt,
        visibleMessages: loadedMessages,
        currentIndex: _replayStartIndex,
        playing: false,
        paused: false,
        finished: false,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
      ),
    );
  }
}
