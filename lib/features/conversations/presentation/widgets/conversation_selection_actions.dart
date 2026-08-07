import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/presentation/widgets/reaction_picker.dart';

List<Widget> buildSelectionActions({
  required BuildContext context,
  required Set<String> selectedMessageIds,
  required void Function(Message) onReplySelected,
  required void Function(String messageId, String emoji) onReactionSelected,
  required VoidCallback onDeleteSelected,
}) {
  return [
    IconButton(icon: const Icon(Icons.star_border), onPressed: () {}),
    IconButton(
      icon: const Icon(Icons.emoji_emotions_outlined),
      onPressed: () async {
        if (selectedMessageIds.length != 1) return;
        final messageId = selectedMessageIds.first;

        await showDialog(
          context: context,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ReactionPicker(
                onSelected: (emoji) {
                  onReactionSelected(messageId, emoji);
                  Navigator.pop(dialogContext);
                },
              ),
            );
          },
        );
      },
    ),
    IconButton(
      icon: const Icon(Icons.reply),
      onPressed: () {
        if (selectedMessageIds.length != 1) return;
        final state = context.read<MessageCubit>().state;
        if (state is! MessageLoaded) return;

        final message = state.messages.firstWhere(
          (m) => m.id == selectedMessageIds.first,
        );
        onReplySelected(message);
      },
    ),
    IconButton(icon: const Icon(Icons.copy), onPressed: () {}),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: onDeleteSelected,
    ),
    PopupMenuButton(
      itemBuilder: (_) => const [
        PopupMenuItem(value: "more", child: Text("More")),
      ],
    ),
  ];
}
