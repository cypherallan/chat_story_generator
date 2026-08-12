part of 'conversation_replay_cubit.dart';

mixin _LoadMixin on _ConversationReplayCubitBase {
  void load(
    List<Message> messages,
    String ownerId,
    List<Person> persons, {
    Map<String, List<Message>> backgroundMessages = const {},
  }) {
    _timer?.cancel();
    _backgroundTimer?.cancel();

    _messages
      ..clear()
      ..addAll(messages);

    _backgroundMessages
      ..clear()
      ..addAll(backgroundMessages);

    _ownerId = ownerId;

    _persons
      ..clear()
      ..addAll(persons);

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
