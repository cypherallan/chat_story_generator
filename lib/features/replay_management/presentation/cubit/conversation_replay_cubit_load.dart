part of 'conversation_replay_cubit.dart';

mixin _LoadMixin on _ConversationReplayCubitBase {
  void load(
    List<Message> messages,
    String ownerId,
    List<Person> persons,
    String projectId,
  ) {
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
        ..sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );

      availableStartTime = sortedMessages.first.createdAt;
      availableEndTime = sortedMessages.last.createdAt;
    }

    final initialReplayStartTime = availableStartTime;

    final initialVisibleMessages = initialReplayStartTime == null
        ? <Message>[]
        : messages
            .where(
              (message) => message.createdAt.isBefore(initialReplayStartTime),
            )
            .toList();

    _replayNotificationMessageCount = null;

    final notification = notificationCubit.state.notification;

    if (notification != null) {
      _replayNotificationMessageCount = notification.triggerMessageIndex;
    }

    final Set<String> emojiSet = {};

    for (final message in messages) {
      for (final character in message.text.characters) {
        if (_isEmoji(character)) {
          emojiSet.add(character);
        }
      }
    }

    emit(
      ConversationReplayState(
        availableEmojis: emojiSet.toList(),
        screen: ReplayScreen.home,
        availableStartTime: availableStartTime,
        availableEndTime: availableEndTime,
        replayStartTime: availableStartTime,
        replayEndTime: availableEndTime,
        visibleMessages: initialVisibleMessages,
        replayNotificationMessageCount: _replayNotificationMessageCount,
      ),
    );
  }
}
