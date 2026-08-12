part of 'conversation_replay_cubit.dart';

mixin _LoadMixin on _ConversationReplayCubitBase {
  void load(
    List<Message> messages,
    String ownerId, {
    List<Message> backgroundMessages = const [],
  }) {
    _timer?.cancel();

    // Messages belonging to the conversation currently being replayed.
    _messages
      ..clear()
      ..addAll(messages);

    // Messages belonging to other conversations.
    //
    // These are NOT displayed inside the open conversation.
    // They will later be used by the replay engine to trigger
    // simulated notifications.
    _backgroundMessages
      ..clear()
      ..addAll(backgroundMessages);

    _ownerId = ownerId;

    final Set<String> emojiSet = {};

    // Collect emojis from the current conversation.
    for (final message in messages) {
      for (final character in message.text.characters) {
        if (_isEmoji(character)) {
          emojiSet.add(character);
        }
      }
    }

    // Also collect emojis from background messages so the
    // replay keyboard remains aware of all replay content.
    for (final message in backgroundMessages) {
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
