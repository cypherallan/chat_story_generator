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
    _visiblePerProject.clear();
    _ownerId = ownerId;
    _persons
      ..clear()
      ..addAll(persons);

    DateTime? availableStartTime;
    DateTime? availableEndTime;
    if (messages.isNotEmpty) {
      final sorted = List<Message>.from(messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      availableStartTime = sorted.first.createdAt;
      availableEndTime = sorted.last.createdAt;
    }
    final initialReplayStartTime = availableStartTime;
    final initialVisibleMessages = initialReplayStartTime == null
        ? <Message>[]
        : messages
            .where((m) => m.createdAt.isBefore(initialReplayStartTime))
            .toList();

    for (final m in initialVisibleMessages) {
      _visiblePerProject.putIfAbsent(m.projectId, () => []).add(m);
    }

    _replayNotificationEvents = [];
    _nextNotificationEventIndex = 0;
    _replayNotificationMessageCount = null;
    try {
      await notificationCubit.loadRecordedEvents(projectId);
      final relevant = notificationCubit.recordedEvents
          .where((e) => e.sourceProjectId == projectId)
          .toList()
        ..sort((a, b) => a.sourceTriggerIndex.compareTo(b.sourceTriggerIndex));
      for (final e in relevant) {
        _replayNotificationEvents.add(ReplayNotificationEvent(
            notification: e.notification,
            triggerIndex: e.sourceTriggerIndex,
            interaction: e.interaction));
      }
      if (_replayNotificationEvents.isNotEmpty) {
        _replayNotificationMessageCount =
            _replayNotificationEvents.first.triggerIndex;
      }
    } catch (_) {
      _replayNotificationEvents = [];
    }

    final Set<String> emojiSet = {};
    for (final m in messages) {
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
