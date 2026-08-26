import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/project_cubit.dart';
import '../../presentation/widgets/chat_list_item_widget.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../conversation_management/presentation/pages/conversation_page.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../person_management/domain/entities/person.dart';
import '../models/chat_list_item.dart';
import '../../../../injection_container.dart' as di;

class ProjectsListWidget extends StatelessWidget {
  final Set<String> selectedChatIds;
  final String? currentPersonId;

  final Function(String) onChatSelected;
  const ProjectsListWidget({
    super.key,
    required this.selectedChatIds,
    required this.onChatSelected,
    required this.currentPersonId,
  });

  @override
  Widget build(BuildContext context) {
    return _ProjectsListBody(
      selectedChatIds: selectedChatIds,
      onChatSelected: onChatSelected,
      currentPersonId: currentPersonId,
    );
  }
}

class _ProjectsListBody extends StatefulWidget {
  final Set<String> selectedChatIds;
  final String? currentPersonId;

  final Function(String) onChatSelected;
  const _ProjectsListBody({
    required this.selectedChatIds,
    required this.onChatSelected,
    required this.currentPersonId,
  });

  @override
  State<_ProjectsListBody> createState() => _ProjectsListBodyState();
}

class _ProjectsListBodyState extends State<_ProjectsListBody> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (personState is! PersonLoaded) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return BlocBuilder<ProjectCubit, ProjectState>(
          builder: (context, state) {
            if (state is ProjectLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ProjectError) {
              return Center(
                child: Text(state.message),
              );
            }

            if (state is ProjectLoaded) {
              final projects = state.projects
                  .where(
                    (project) =>
                        widget.currentPersonId == null ||
                        project.ownerId == widget.currentPersonId,
                  )
                  .toList();

              projects.sort((a, b) {
                final aTime = a.lastMessageTime ?? a.createdAt;

                final bTime = b.lastMessageTime ?? b.createdAt;

                return bTime.compareTo(aTime);
              });

              if (projects.isEmpty) {
                return const Center(
                  child: Text(
                    'No Chats yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];

                  final bool isGroup = project.participantIds.length > 2;

                  Person? otherPerson;

                  if (!isGroup) {
                    final otherPersonId = project.participantIds.firstWhere(
                      (id) => id != project.ownerId,
                      orElse: () => project.ownerId,
                    );

                    final matches = personState.persons.where(
                      (p) => p.id == otherPersonId,
                    );

                    if (matches.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    otherPerson = matches.first;
                  }

                  String lastMessagePreview = project.lastMessage;

                  if (project.lastMessageImagePath != null) {
                    lastMessagePreview = project.lastMessage.isNotEmpty
                        ? '🖼️ ${project.lastMessage}'
                        : 'Photo';
                  }

                  if (isGroup && project.lastSenderId != null) {
                    if (project.lastSenderId == project.ownerId) {
                      lastMessagePreview = 'You: $lastMessagePreview';
                    } else {
                      final sender = personState.persons.where(
                        (p) => p.id == project.lastSenderId,
                      );

                      lastMessagePreview = sender.isNotEmpty
                          ? '${sender.first.name}: $lastMessagePreview'
                          : 'Unknown: $lastMessagePreview';
                    }
                  }

                  final chat = ChatListItem(
                    project: project,
                    chatName: isGroup ? project.title : otherPerson!.name,
                    avatarPath: isGroup ? null : otherPerson!.avatarPath,
                    groupImagePath: project.groupImagePath,
                    verified: isGroup ? false : otherPerson!.isVerified,
                    lastMessage: lastMessagePreview,
                    lastMessageImagePath: project.lastMessageImagePath,
                    lastMessageTime: project.lastMessageTime,
                    lastMessageStatus: project.lastMessageStatus,
                    isLastMessageMine: project.lastSenderId == project.ownerId,
                    unreadCount: project.unreadCount,
                  );

                  return ChatListItemWidget(
                    chat: chat,
                    isSelected: widget.selectedChatIds.contains(project.id),
                    onLongPress: () {
                      widget.onChatSelected(project.id);
                    },
                    onTap: () async {
                      if (widget.selectedChatIds.isNotEmpty) {
                        widget.onChatSelected(project.id);
                        return;
                      }

                      await context
                          .read<ProjectCubit>()
                          .clearUnreadCount(project.id);

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                  value: context.read<ProjectCubit>()),
                              BlocProvider(
                                  create: (_) => di.sl<MessageCubit>()
                                    ..loadMessages(project.id)),
                              BlocProvider.value(
                                  value: context.read<PersonCubit>()),
                            ],
                            child: ConversationPage(project: project),
                          ),
                        ),
                      );

                      if (context.mounted) {
                        await context.read<ProjectCubit>().loadProjects();
                      }
                    },
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
