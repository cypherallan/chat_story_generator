part of 'conversation_replay_cubit.dart';

mixin _UtilsMixin on _ConversationReplayCubitBase {
  void hideKeyboard() {
    emit(
      state.copyWith(
        keyboardVisible: false,
        emojiKeyboardVisible: false,
      ),
    );
  }

  @override
  bool _isEmoji(String character) {
    if (character.isEmpty) {
      return false;
    }

    final rune = character.runes.first;

    return (rune >= 0x1F300 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF);
  }
}
