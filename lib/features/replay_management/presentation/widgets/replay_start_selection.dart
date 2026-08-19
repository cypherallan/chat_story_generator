import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';
import 'replay_start_message_picker.dart';
import 'replay_start_time_picker.dart';

enum ReplayStartChoice {
  time,
  message,
}

class ReplayStartSelection {
  final ReplayStartChoice choice;
  final DateTime? startTime;
  final String? messageId;

  const ReplayStartSelection({
    required this.choice,
    this.startTime,
    this.messageId,
  });
}

Future<ReplayStartSelection?> showReplayStartSelection(
  BuildContext context,
  List<Message> messages,
) async {
  final sortedMessages = List<Message>.from(messages)
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final result = await showDialog<ReplayStartSelection>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Where do you want the replay to start from?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose method:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TIME
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: const Text(
                'Choose a time to start the replay from.',
              ),
              onTap: () async {
                final startTime = await showReplayStartTimePicker(
                  dialogContext,
                  sortedMessages,
                );

                if (startTime != null && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    ReplayStartSelection(
                      choice: ReplayStartChoice.time,
                      startTime: startTime,
                    ),
                  );
                }
              },
            ),

            const Divider(),

            // MESSAGE
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.message_outlined),
              title: const Text('Message'),
              subtitle: const Text(
                'Choose a message to start replay after.',
              ),
              onTap: () async {
                final messageId = await showReplayStartMessagePicker(
                  dialogContext,
                  sortedMessages,
                );

                if (messageId != null && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(
                    ReplayStartSelection(
                      choice: ReplayStartChoice.message,
                      messageId: messageId,
                    ),
                  );
                }
              },
            ),
          ],
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

  return result;
}
