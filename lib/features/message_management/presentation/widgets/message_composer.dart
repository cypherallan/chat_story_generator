import 'package:flutter/material.dart';
import '../../../person_management/domain/entities/person.dart';
import 'dart:io';

class MessageComposer extends StatefulWidget {
  final List<Person> participants;
  final String selectedSenderId;
  final ValueChanged<String> onSenderChanged;
  final Function(String senderId, String text) onSend;

  const MessageComposer({
    super.key,
    required this.participants,
    required this.selectedSenderId,
    required this.onSenderChanged,
    required this.onSend,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final controller = TextEditingController();

  void _send() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    widget.onSend(
      widget.selectedSenderId,
      text,
    );

    controller.clear();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    PopupMenuButton<String>(
                      onSelected: widget.onSenderChanged,
                      itemBuilder: (context) {
                        return widget.participants.map((person) {
                          return PopupMenuItem<String>(
                            value: person.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    person.name[0].toUpperCase(),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(person.name),
                                ),
                                if (person.isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Builder(
                        builder: (context) {
                          final currentPerson = widget.participants.firstWhere(
                            (person) => person.id == widget.selectedSenderId,
                          );

                          ImageProvider? image;

                          if (currentPerson.avatarPath != null) {
                            if (currentPerson.avatarPath!.startsWith('http')) {
                              image = NetworkImage(currentPerson.avatarPath!);
                            } else {
                              image = FileImage(
                                File(currentPerson.avatarPath!),
                              );
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundImage: image,
                                  child: image == null
                                      ? Text(
                                          currentPerson.name[0].toUpperCase(),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  currentPerson.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                      ),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 24,
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                ),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
