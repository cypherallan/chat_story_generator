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

// ------------------------------------------------------------
// FIND WHERE THE TRIGGERED NOTIFICATION BELONGS IN THE REPLAY
// ------------------------------------------------------------

    _replayNotificationMessageCount = null;

    final notification = notificationCubit.state.notification;

    if (notification != null) {
      _replayNotificationMessageCount = notification.triggerMessageIndex;
    } else {
      // ------------------------------------------------------------
      // AVAILABLE EMOJIS
      // ------------------------------------------------------------

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
        ),
      );
    }
  }
}
