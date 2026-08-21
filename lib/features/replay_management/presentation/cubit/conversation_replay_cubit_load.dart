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

    _ownerId = ownerId;

    _persons
      ..clear()
      ..addAll(persons);

    DateTime? availableStartTime;
    DateTime? availableEndTime;

    if (messages.isNotEmpty) {
      final sortedMessages = List<Message>.from(messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      availableStartTime = sortedMessages.first.createdAt;
      availableEndTime = sortedMessages.last.createdAt;
    }

    final initialReplayStartTime = availableStartTime;

    final initialVisibleMessages = initialReplayStartTime == null
        ? <Message>[]
        : messages
            .where(
                (message) => message.createdAt.isBefore(initialReplayStartTime))
            .toList();

    // ---------- MULTI-NOTIFICATION SUPPORT (from recorded events) ----------
    _replayNotificationEvents = [];
    _nextNotificationEventIndex = 0;
    _replayNotificationMessageCount = null;

    try {
      // Only events that were triggered while inside THIS conversation
      final relevantEvents = notificationCubit.recordedEvents
          .where((e) => e.sourceProjectId == projectId)
          .toList()
        ..sort((a, b) => a.sourceTriggerIndex.compareTo(b.sourceTriggerIndex));

      print('=== RECORDED EVENTS FOR PROJECT $projectId ===');
      print('Total relevant events: ${relevantEvents.length}');
      for (final e in relevantEvents) {
        print('  sourceIndex=${e.sourceTriggerIndex}, '
            'target=${e.notification.projectId}, '
            'interaction=${e.interaction}, '
            'targetVisibleCount=${e.targetVisibleCount}');
      }
      print('==============================================');

      for (final e in relevantEvents) {
        _replayNotificationEvents.add(
          ReplayNotificationEvent(
            notification: e.notification,
            triggerIndex: e.sourceTriggerIndex,
            interaction: e.interaction,
          ),
        );
      }

      if (_replayNotificationEvents.isNotEmpty) {
        _replayNotificationMessageCount =
            _replayNotificationEvents.first.triggerIndex;
      }
    } catch (e, st) {
      print('ERROR building replay notification events: $e');
      print(st);
      _replayNotificationEvents = [];
    }
// -----------------------------------------------------------------------
    // ------------------------------------------------

    final Set<String> emojiSet = {};
    for (final message in messages) {
      for (final character in message.text.characters) {
        if (_isEmoji(character)) {
          emojiSet.add(character);
        }
      }
    }
    print('=== REPLAY NOTIFICATIONS LOADED ===');
    print('Project ID: $projectId');
    print('Total events: ${_replayNotificationEvents.length}');
    for (final e in _replayNotificationEvents) {
      print('  → triggerIndex=${e.triggerIndex}, '
          'messageId=${e.notification.messageId}, '
          'interaction=${e.interaction}');
    }
    print('===================================');

    emit(
      ConversationReplayState(
        availableEmojis: emojiSet.toList(),
        screen: ReplayScreen.home,
        availableStartTime: availableStartTime,
        availableEndTime: availableEndTime,
        replayStartTime: availableStartTime,
        replayEndTime: availableEndTime,
        visibleMessages: initialVisibleMessages,
        // keep the old field for now (can be removed later)
        replayNotificationMessageCount: _replayNotificationMessageCount,
      ),
    );
  }
}
