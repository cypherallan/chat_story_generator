import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../conversations/presentation/pages/group_info_page.dart';
import '../../../message_management/presentation/widgets/reaction_picker.dart';
import 'conversation_header.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';

class ConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Project project;
  final bool isSelectionMode;
  final int selectedCount;
  final Set<String> typingPersonIds;
  final bool otherPersonTyping;
  final VoidCallback onClearSelection;
  final VoidCallback onPreviewPressed;
  final Set<String> selectedMessageIds;
  final void Function(Message) onReplySelected;
  final void Function(String messageId, String emoji) onReactionSelected;
  final VoidCallback onDeleteSelected;

  const ConversationAppBar({
    super.key,
    required this.project,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.typingPersonIds,
    required this.otherPersonTyping,
    required this.onClearSelection,
    required this.onPreviewPressed,
    required this.selectedMessageIds,
    required this.onReplySelected,
    required this.onReactionSelected,
    required this.onDeleteSelected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onClearSelection,
            )
          : null,
      titleSpacing: 0,
      title: isSelectionMode
          ? Text("$selectedCount")
          : BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                final isGroup = project.participantIds.length > 2;

                if (isGroup) {
                  if (state is PersonLoaded) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider.value(
                                  value: context.read<PersonCubit>(),
                                ),
                                BlocProvider.value(
                                  value: context.read<ProjectCubit>(),
                                ),
                              ],
                              child: GroupInfoPage(
                                project: project,
                                persons: state.persons,
                              ),
                            ),
                          ),
                        );
                      },
                      child: ConversationHeader(
                        project: project,
                        persons: state.persons,
                        typingPersonIds: typingPersonIds,
                      ),
                    );
                  }
                  return const Text('Conversation');
                }

                if (state is PersonLoaded) {
                  final otherPersonId = project.participantIds.firstWhere(
                    (id) => id != project.ownerId,
                    orElse: () => project.ownerId,
                  );

                  final otherPerson = state.persons.firstWhere(
                    (person) => person.id == otherPersonId,
                  );

                  return ConversationHeader(
                    person: otherPerson,
                    isTyping: otherPersonTyping,
                  );
                }

                return const Text('Conversation');
              },
            ),
      actions: isSelectionMode
          ? [
              IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: () {},
              ),
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
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDeleteSelected,
              ),
              PopupMenuButton(
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "more",
                    child: Text("More"),
                  ),
                ],
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined),
                onPressed: () {},
              ),
              BlocBuilder<MessageCubit, MessageState>(
                builder: (context, state) {
                  return IconButton(
                    tooltip: "Preview Conversation",
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed:
                        state is! MessageLoaded ? null : onPreviewPressed,
                  );
                },
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: "view_contact",
                    child: Text("View contact"),
                  ),
                  PopupMenuItem(
                    value: "media",
                    child: Text("Media, links and docs"),
                  ),
                  PopupMenuItem(
                    value: "search",
                    child: Text("Search"),
                  ),
                  PopupMenuItem(
                    value: "mute",
                    child: Text("Mute notifications"),
                  ),
                ],
              ),
            ],
    );
  }
}
