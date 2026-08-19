import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';

Future<DateTime?> showReplayStartTimePicker(
  BuildContext context,
  List<Message> messages,
) async {
  if (messages.isEmpty) {
    return null;
  }

  final firstMessageTime = messages.first.createdAt;
  final lastMessageTime = messages.last.createdAt;

  DateTime selectedDate = firstMessageTime;

  TimeOfDay selectedTime = TimeOfDay.fromDateTime(
    firstMessageTime,
  );

  final result = await showDialog<DateTime>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );

          return AlertDialog(
            title: const Text('Replay starting time'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose the time where the replay should begin.',
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(selectedDate),
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(
                        firstMessageTime.year,
                        firstMessageTime.month,
                        firstMessageTime.day,
                      ),
                      lastDate: DateTime(
                        lastMessageTime.year,
                        lastMessageTime.month,
                        lastMessageTime.day,
                      ),
                    );

                    if (pickedDate != null) {
                      setDialogState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    selectedTime.format(context),
                  ),
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );

                    if (pickedTime != null) {
                      setDialogState(() {
                        selectedTime = pickedTime;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Available: '
                  '${MaterialLocalizations.of(context).formatMediumDate(firstMessageTime)} '
                  '${TimeOfDay.fromDateTime(firstMessageTime).format(context)}'
                  ' – '
                  '${MaterialLocalizations.of(context).formatMediumDate(lastMessageTime)} '
                  '${TimeOfDay.fromDateTime(lastMessageTime).format(context)}',
                  style: Theme.of(context).textTheme.bodySmall,
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
              FilledButton(
                onPressed: () {
                  if (selectedDateTime.isBefore(firstMessageTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Start time cannot be before the first message.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (selectedDateTime.isAfter(lastMessageTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Start time cannot be after the last message.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop(
                    selectedDateTime,
                  );
                },
                child: const Text('CONTINUE'),
              ),
            ],
          );
        },
      );
    },
  );

  return result;
}
