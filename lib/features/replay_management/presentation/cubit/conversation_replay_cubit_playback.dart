part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase, _NavigationMixin {
  void play() {
    if (state.playing) {
      return;
    }
    if (state.finished) {
      _timer?.cancel();
      _nextNotificationEventIndex = 0;
      _nextDeletionIndex = 0;
      final initialVisible = _messages.take(_replayStartIndex).toList();
      emit(
        state.copyWith(
          visibleMessages: initialVisible,
          currentIndex: _replayStartIndex,
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
          lastPressedEmoji: null,
          shiftPressed: false,
          clearReplayNotification: true,
        ),
      );
      _lastPlayedTime = _replayStartIndex > 0
          ? _messages[_replayStartIndex - 1].createdAt
          : _messages.isNotEmpty
              ? _messages[0].createdAt
              : DateTime.now();
      _playNext();
      return;
    }

    _nextNotificationEventIndex = 0;

    if (state.replayStartMethod == ReplayStartMethod.time) {
      if (state.replayStartTime != null) {
        _replayStartIndex = _messages.indexWhere(
          (m) => !m.createdAt.isBefore(state.replayStartTime!),
        );
        if (_replayStartIndex == -1) _replayStartIndex = _messages.length;
      } else {
        _replayStartIndex = 0;
      }
    }

    emit(
      state.copyWith(
        playing: true,
        paused: false,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        clearReplayNotification: true,
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
    notificationCubit.clear();
    emit(const ConversationReplayState(keyboardVisible: false));
  }

  @override
  Duration _compressRealGap(Duration real) {
    if (real.isNegative || real == Duration.zero) return Duration.zero;
    final s = real.inMilliseconds / 1000.0;
    var rs = 0.8 + (log(s + 1) * 1.2);
    rs = rs.clamp(0.8, 6.0);
    return Duration(milliseconds: (rs * 1000).round());
  }

  @override
  void _playNext() {
    if (!state.playing) return;
    if (state.currentIndex < _replayStartIndex) {
      emit(state.copyWith(currentIndex: _replayStartIndex));
    }

    while (_nextDeletionIndex < _deletionEvents.length) {
      final del = _deletionEvents[_nextDeletionIndex];
      final alreadyVisible =
          state.visibleMessages.any((m) => m.id == del.id && !m.isDeleted);
      if (!alreadyVisible) break;

      if (state.currentIndex >= _messages.length) {
        _playDeletion(del);
        return;
      }
      final nextMsg = _messages[state.currentIndex];
      if (!del.deletedAt!.isAfter(nextMsg.createdAt)) {
        _playDeletion(del);
        return;
      }
      break;
    }

    if (state.currentProjectId != null) {
      final currentPid = state.currentProjectId!;
      final playedOfSource = _messages
          .take(state.currentIndex)
          .where((m) => m.projectId == currentPid)
          .length;

      for (int i = _nextNotificationEventIndex;
          i < _replayNotificationEvents.length;
          i++) {
        final ev = _replayNotificationEvents[i];
        if (ev.sourceProjectId != currentPid) continue;
        if (ev.triggerIndex == playedOfSource) {
          _nextNotificationEventIndex = i;
          _replayNotificationEvent(ev);
          return;
        }
        if (ev.triggerIndex > playedOfSource) {
          break;
        }
      }
    }

    if (state.currentIndex >= _messages.length) {
      if (_returnMessages.isNotEmpty &&
          _returnProjectId != null &&
          _messages.length < 7) {
        returnFromNotificationConversation();
        return;
      }
      emit(state.copyWith(
          playing: false,
          finished: true,
          clearReplayNotification: true,
          typing: false,
          keyboardVisible: true,
          emojiKeyboardVisible: false,
          composerText: '',
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
          shiftPressed: false));
      return;
    }

    final messageIndex = state.currentIndex;
    final message = _messages[messageIndex];

    if (state.currentProjectId != null &&
        message.projectId != state.currentProjectId) {
      _timer?.cancel();
      emit(state.copyWith(
          visualInteraction: ReplayVisualInteraction.backTap,
          playing: false,
          paused: true));
      final prev = _messages[messageIndex - 1];
      final realGap = message.createdAt.difference(prev.createdAt);
      final gap = _compressRealGap(realGap);
      final filteredVisible = _visiblePerProject[message.projectId] ??
          _messages
              .take(messageIndex)
              .where((m) => m.projectId == message.projectId)
              .toList();
      _visiblePerProject[message.projectId] =
          List<Message>.from(filteredVisible);
      _timer = Timer(const Duration(milliseconds: 380), () {
        if (isClosed) return;
        emit(state.copyWith(
            visualInteraction: ReplayVisualInteraction.none,
            screen: ReplayScreen.home,
            highlightedChatProjectId: message.projectId,
            currentProjectId: null,
            visibleMessages: const []));
        _timer = Timer(const Duration(milliseconds: 350), () {
          if (isClosed) return;
          emit(state.copyWith(
              visualInteraction: ReplayVisualInteraction.chatTap));
          _timer = Timer(const Duration(milliseconds: 380), () {
            if (isClosed) return;
            emit(state.copyWith(
                screen: ReplayScreen.conversation,
                currentProjectId: message.projectId,
                visualInteraction: ReplayVisualInteraction.none,
                clearHighlightedChat: true,
                visibleMessages: filteredVisible,
                typing: false,
                typingPersonId: null));
            _timer = Timer(gap, () {
              if (isClosed) return;
              _lastPlayedTime = message.createdAt;
              emit(state.copyWith(playing: true, paused: false));
              if (message.senderId == _ownerId) {
                _typeOwnerMessage(message);
              } else {
                _typeOtherPersonMessage(message);
              }
            });
          });
        });
      });
      return;
    }

    Duration gap;
    if (_lastPlayedTime == null) {
      gap = Duration.zero;
    } else {
      gap = _compressRealGap(message.createdAt.difference(_lastPlayedTime!));
    }

    _timer = Timer(gap, () {
      if (!state.playing) return;
      _lastPlayedTime = message.createdAt;
      if (message.senderId == _ownerId) {
        _typeOwnerMessage(message);
      } else {
        _typeOtherPersonMessage(message);
      }
    });
  }

  void _playDeletion(Message del) {
    final realGap = del.deletedAt!.difference(_lastPlayedTime ?? del.createdAt);
    final gap = _compressRealGap(realGap);
    _timer = Timer(gap, () {
      if (!state.playing) return;
      _lastPlayedTime = del.deletedAt;
      _startVisualDeletion(del);
    });
  }

  Future<void> _handleReplayNotificationTap(
      ReplayNotificationEvent event) async {
    _timer?.cancel();
    emit(state.copyWith(
        visualInteraction: ReplayVisualInteraction.notificationTap,
        replayNotificationInteraction: ReplayNotificationInteraction.tapped,
        playing: false,
        paused: true,
        finished: false));
    await Future.delayed(const Duration(milliseconds: 350));
    if (isClosed) return;
    notificationCubit.hideNotificationPreserveInteraction();
    await openConversationFromNotification(
        projectId: event.notification.projectId,
        notificationMessageId: event.notification.messageId);
  }

  void _handleReplayNotificationSwipe() {
    final swiped = state.replayNotification;
    if (swiped != null) {
      final targetId = swiped.projectId;
      final idx = _messages.indexWhere((m) => m.id == swiped.messageId);
      if (idx != -1) {
        final msg = _messages[idx];
        _visiblePerProject.putIfAbsent(targetId, () => []);
        if (!_visiblePerProject[targetId]!.any((m) => m.id == msg.id)) {
          _visiblePerProject[targetId]!.add(msg);
        }
      }
      if (state.currentIndex < _messages.length &&
          _messages[state.currentIndex].id == swiped.messageId) {
        emit(state.copyWith(currentIndex: state.currentIndex + 1));
      }
    }

    _timer?.cancel();
    emit(state.copyWith(
        visualInteraction: ReplayVisualInteraction.notificationSwipe,
        replayNotificationInteraction: ReplayNotificationInteraction.swiped));
    _timer = Timer(const Duration(milliseconds: 450), () {
      if (isClosed) return;
      notificationCubit.hideNotificationPreserveInteraction();
      emit(state.copyWith(
          clearReplayNotification: true,
          visualInteraction: ReplayVisualInteraction.none));
      _timer = Timer(const Duration(milliseconds: 300), _playNext);
    });
  }

  void _replayNotificationEvent(ReplayNotificationEvent event) {
    _nextNotificationEventIndex++;
    // play notification sound when banner shows
    soundService.playNotification();
    emit(state.copyWith(
        replayNotification: event.notification,
        replayNotificationInteraction: ReplayNotificationInteraction.none));
    switch (event.interaction) {
      case NotificationInteraction.tapped:
        _timer = Timer(const Duration(seconds: 3), () {
          if (!state.playing) return;
          _handleReplayNotificationTap(event);
        });
        break;
      case NotificationInteraction.swiped:
        _timer = Timer(const Duration(seconds: 3), () {
          if (!state.playing) return;
          _handleReplayNotificationSwipe();
        });
        break;
      case NotificationInteraction.expired:
      case NotificationInteraction.none:
        _timer = Timer(const Duration(seconds: 3), () {
          if (!state.playing) return;
          emit(state.copyWith(
              clearReplayNotification: true,
              replayNotificationInteraction:
                  ReplayNotificationInteraction.expired));
          _timer = Timer(const Duration(milliseconds: 300), _playNext);
        });
        break;
    }
  }

  void _typeOtherPersonMessage(Message message) {
    final delay = _humanTypingDuration(message.originalText ?? message.text);
    emit(state.copyWith(
        typing: true,
        typingPersonId: message.senderId,
        onlinePersonId: message.senderId,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false));
    _timer = Timer(delay, () {
      if (!state.playing) return;
      final messageToShow = message.isDeleted
          ? message.copyWith(
              text: message.originalText ?? message.text, isDeleted: false)
          : message;
      final updatedMessages = List<Message>.from(state.visibleMessages)
        ..add(messageToShow);
      _visiblePerProject[message.projectId] =
          List<Message>.from(updatedMessages);
      // SOUND: incoming
      soundService.playReceive();
      emit(state.copyWith(
          typing: false,
          typingPersonId: null,
          visibleMessages: updatedMessages,
          currentIndex: state.currentIndex + 1,
          keyboardVisible: true));
      _timer = Timer(const Duration(milliseconds: 650), _playNext);
    });
  }
}
