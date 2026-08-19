import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';

Future<String?> showReplayStartMessagePicker(
  BuildContext context,
  List<Message> messages,
) async {
  if (messages.isEmpty) {
    return null;
  }

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Choose a message',
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.55,
          child: ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final message = messages[index];

              final time = TimeOfDay.fromDateTime(
                message.createdAt,
              ).format(context);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                title: Text(
                  message.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(time),
                onTap: () {
                  Navigator.of(dialogContext).pop(
                    message.id,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('CANCEL'),
          ),
        ],
      );
    },
  );
}
