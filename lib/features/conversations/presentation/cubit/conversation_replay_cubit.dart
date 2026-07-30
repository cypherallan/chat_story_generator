import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';

class ConversationReplayCubit extends Cubit<List<Message>> {
  ConversationReplayCubit() : super([]);

  List<Message> _allMessages = [];

  int _currentIndex = -1;

  void loadMessages(List<Message> messages) {
    _allMessages = messages;
    _currentIndex = -1;
    emit([]);
  }

  void showNextMessage() {
    if (_currentIndex + 1 >= _allMessages.length) return;

    _currentIndex++;

    emit(
      _allMessages.sublist(
        0,
        _currentIndex + 1,
      ),
    );
  }

  void reset() {
    _currentIndex = -1;
    emit([]);
  }

  bool get finished => _currentIndex >= _allMessages.length - 1;

  int get currentIndex => _currentIndex;

  int get totalMessages => _allMessages.length;
}
