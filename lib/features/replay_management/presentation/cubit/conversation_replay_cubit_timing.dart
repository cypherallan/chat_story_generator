part of 'conversation_replay_cubit.dart';

mixin _TimingMixin on _ConversationReplayCubitBase {
  List<Duration> _realCharDelays = [];
  int _realDelayIndex = 0;

  void setRealTypingDelays(List<Duration> delays) {
    _realCharDelays = delays;
    _realDelayIndex = 0;
  }

  void clearRealTypingDelays() {
    _realCharDelays = [];
    _realDelayIndex = 0;
  }

  @override
  Duration _humanCharacterDelay({
    required String character,
    required String? nextCharacter,
  }) {
    // USE REAL TIMING IF AVAILABLE - 1:1 with normal conversation
    if (_realDelayIndex < _realCharDelays.length) {
      final real = _realCharDelays[_realDelayIndex++];
      // clamp to avoid 0ms on fast typing
      return Duration(milliseconds: real.inMilliseconds.clamp(15, 600));
    }

    var milliseconds = 75 + _random.nextInt(120);

    if (character == ' ') {
      milliseconds += 50 + _random.nextInt(90);
    }
    if (character == '.' ||
        character == ',' ||
        character == '!' ||
        character == '?' ||
        character == ':') {
      milliseconds += 100 + _random.nextInt(180);
    }

    if (character == '.' ||
        character == '!' ||
        character == '?' ||
        character == ',') {
      milliseconds += 80 + _random.nextInt(150);
    }
    if (_random.nextInt(18) == 0) {
      milliseconds += 250 + _random.nextInt(500);
    }
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

    final basePerCharacter = 210 + _random.nextInt(90);

    var milliseconds = characters * basePerCharacter;

    milliseconds = max(milliseconds, 1200);

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

    final punctuationCount = RegExp(r'[.!?,]').allMatches(text).length;

    milliseconds += punctuationCount * 250;

    final wordCount = text.trim().split(RegExp(r'\s+')).length;

    milliseconds += wordCount * 60;

    if (_random.nextInt(8) == 0) {
      milliseconds += 500 + _random.nextInt(1000);
    }

    return Duration(milliseconds: milliseconds);
  }
}
