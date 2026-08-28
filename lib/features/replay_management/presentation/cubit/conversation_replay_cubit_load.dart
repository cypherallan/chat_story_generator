part of 'conversation_replay_cubit.dart';

mixin _LoadMixin on _ConversationReplayCubitBase {
  Future<void> load(
    List<Message> messages,
    String ownerId,
    List<Person> persons,
    String projectId,
  ) async {
    _timer?.cancel();
    _messages
      ..clear()
      ..addAll(messages);

    // --- sort and build deletion timeline ---
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _deletionEvents = _messages
        .where((m) => m.isDeleted && m.deletedAt != null)
        .toList()
      ..sort((a, b) => a.deletedAt!.compareTo(b.deletedAt!));
    _nextDeletionIndex = 0;
    _lastPlayedTime = _messages.isNotEmpty ? _messages.first.createdAt : null;

    _visiblePerProject.clear();
    _ownerId = ownerId;
    _persons
      ..clear()
      ..addAll(persons);

    DateTime? availableStartTime;
    DateTime? availableEndTime;
    if (_messages.isNotEmpty) {
      availableStartTime = _messages.first.createdAt;
      availableEndTime = _messages.last.createdAt;
    }
    final initialReplayStartTime = availableStartTime;
    final initialVisibleMessages = initialReplayStartTime == null
        ? <Message>[]
        : _messages
            .where((m) => m.createdAt.isBefore(initialReplayStartTime))
            .toList();

    for (final m in initialVisibleMessages) {
      _visiblePerProject.putIfAbsent(m.projectId, () => []).add(m);
    }

    _replayNotificationEvents = [];
    _nextNotificationEventIndex = 0;
    _replayNotificationMessageCount = null;
    try {
      final projectIdsInReplay =
          _messages.map((m) => m.projectId).toSet().toList();
      await notificationCubit.loadAllRecordedEvents(projectIdsInReplay);

      // KEEP CHRONOLOGICAL ORDER (when you triggered live), not triggerIndex
      final relevant = notificationCubit.recordedEvents
          .where((e) => projectIdsInReplay.contains(e.sourceProjectId))
          .toList()
        ..sort((a, b) =>
            a.notification.createdAt.compareTo(b.notification.createdAt));

      for (final e in relevant) {
        _replayNotificationEvents.add(ReplayNotificationEvent(
            notification: e.notification,
            triggerIndex: e.sourceTriggerIndex,
            interaction: e.interaction,
            sourceProjectId: e.sourceProjectId));
      }
    } catch (_) {
      _replayNotificationEvents = [];
    }

    final Set<String> emojiSet = {};
    for (final m in _messages) {
      for (final c in m.text.characters) {
        if (_isEmoji(c)) emojiSet.add(c);
      }
    }

    emit(ConversationReplayState(
      availableEmojis: emojiSet.toList(),
      screen: ReplayScreen.home,
      availableStartTime: availableStartTime,
      availableEndTime: availableEndTime,
      replayStartTime: availableStartTime,
      replayEndTime: availableEndTime,
      visibleMessages: initialVisibleMessages,
      replayNotificationMessageCount: _replayNotificationMessageCount,
    ));
  }
}
