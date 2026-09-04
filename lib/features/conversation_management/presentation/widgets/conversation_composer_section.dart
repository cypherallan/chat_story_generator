import 'package:flutter/material.dart';
import '../../../../injection_container.dart' as di;
import '../../../../core/services/sound_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../group_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/presentation/widgets/message_composer.dart';

class ConversationComposerSection extends StatelessWidget {
  final Project project;
  final String selectedSenderId;
  final Message? replyingTo;
  final VoidCallback onCancelReply;
  final void Function(String) onSenderChanged;
  final VoidCallback onTypingStarted;
  final VoidCallback onTypingStopped;
  final void Function(Map<String, dynamic>) onImageSelected;
  final void Function(
    String senderId,
    String text,
    List<MessageTypingEvent> typingEvents,
  ) onSend;

  const ConversationComposerSection({
    super.key,
    required this.project,
    required this.selectedSenderId,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSenderChanged,
    required this.onTypingStarted,
    required this.onTypingStopped,
    required this.onImageSelected,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, state) {
        if (state is! PersonLoaded) return const SizedBox.shrink();

        final participants = state.persons
            .where((person) => project.participantIds.contains(person.id))
            .toList();

        return MessageComposer(
          replyingTo: replyingTo,
          onCancelReply: onCancelReply,
          participants: participants,
          selectedSenderId: selectedSenderId,
          ownerId: project.ownerId,
          soundService: di.sl<SoundService>(),
          onSenderChanged: onSenderChanged,
          onTypingStarted: onTypingStarted,
          onTypingStopped: onTypingStopped,
          onImageSelected: onImageSelected,
          onSend: onSend,
        );
      },
    );
  }
}
