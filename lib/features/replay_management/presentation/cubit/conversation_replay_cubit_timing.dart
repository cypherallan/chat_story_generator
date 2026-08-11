part of 'conversation_replay_cubit.dart';

mixin _TimingMixin on _ConversationReplayCubitBase {
  @override
  Duration _humanCharacterDelay({
    required String character,
    required String? nextCharacter,
  }) {
    // Base human keyboard interval.
    var milliseconds = 75 + _random.nextInt(120);

    // Spaces usually create a slightly larger pause.
    if (character == ' ') {
      milliseconds += 50 + _random.nextInt(90);
    }

    // Punctuation usually causes a small pause.
    if (character == '.' ||
        character == ',' ||
        character == '!' ||
        character == '?' ||
        character == ':') {
      milliseconds += 100 + _random.nextInt(180);
    }

    // Slight pause after punctuation before the next word.
    if (character == '.' ||
        character == '!' ||
        character == '?' ||
        character == ',') {
      milliseconds += 80 + _random.nextInt(150);
    }

    // Occasional hesitation, like a real person typing.
    if (_random.nextInt(18) == 0) {
      milliseconds += 250 + _random.nextInt(500);
    }

    // Another small pause before punctuation.
    if (nextCharacter == '.' ||
        nextCharacter == ',' ||
        nextCharacter == '!' ||
        nextCharacter == '?') {
      milliseconds += 50 + _random.nextInt(100);
    }

    return Duration(milliseconds: milliseconds);
  }

  @override
  Duration _humanTypingDuration(String text) {
    if (text.trim().isEmpty) {
      return const Duration(milliseconds: 800);
    }

    final characters = text.characters.length;

    // Approximate human typing speed:
    //
    // 180-260 characters/minute gives roughly
    // 230-330ms per character.
    //
    // We use a randomized range so every replay doesn't feel identical.

    final basePerCharacter = 210 + _random.nextInt(90); // 210-299 ms

    var milliseconds = characters * basePerCharacter;

    // Minimum typing time.
    milliseconds = max(milliseconds, 1200);

    // Short messages shouldn't feel unnaturally slow.
    if (characters <= 5) {
      milliseconds = 1200 + _random.nextInt(700);
    } else if (characters <= 12) {
      milliseconds = 1800 + _random.nextInt(900);
    } else if (characters <= 25) {
      milliseconds = 2600 + _random.nextInt(1200);
    } else if (characters <= 50) {
      milliseconds = 4000 + _random.nextInt(1600);
    } else if (characters <= 90) {
      milliseconds = 6000 + _random.nextInt(2200);
    } else {
      milliseconds = 8000 + _random.nextInt(3000);
    }

    // Extra time for punctuation and pauses between sentences.
    final punctuationCount = RegExp(r'[.!?,]').allMatches(text).length;

    milliseconds += punctuationCount * 250;

    // Spaces represent word transitions.
    final wordCount = text.trim().split(RegExp(r'\s+')).length;

    milliseconds += wordCount * 60;

    // Occasional longer hesitation.
    if (_random.nextInt(8) == 0) {
      milliseconds += 500 + _random.nextInt(1000);
    }

    return Duration(milliseconds: milliseconds);
  }
}