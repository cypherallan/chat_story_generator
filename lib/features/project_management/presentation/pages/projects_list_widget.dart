import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/project_cubit.dart';
import '../../presentation/widgets/chat_list_item_widget.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../conversations/presentation/pages/conversation_page.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';

import '../../../person_management/domain/entities/person.dart';
import '../models/chat_list_item.dart';

import '../../../../injection_container.dart' as di;

class ProjectsListWidget extends StatelessWidget {
  final Set<String> selectedChatIds;
  final Function(String) onChatSelected;

  const ProjectsListWidget({
    super.key,
    required this.selectedChatIds,
    required this.onChatSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _ProjectsListBody(
      selectedChatIds: selectedChatIds,
      onChatSelected: onChatSelected,
    );
  }
}

class _ProjectsListBody extends StatefulWidget {
  final Set<String> selectedChatIds;
  final Function(String) onChatSelected;

  const _ProjectsListBody({
    required this.selectedChatIds,
    required this.onChatSelected,
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
              final projects = [...state.projects];

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

                    otherPerson = personState.persons.firstWhere(
                      (p) => p.id == otherPersonId,
                    );
                  }

                  final chat = ChatListItem(
                    project: project,
                    chatName: isGroup ? project.title : otherPerson!.name,
                    avatarPath: isGroup ? null : otherPerson!.avatarPath,
                    groupImagePath: project.groupImagePath,
                    verified: isGroup ? false : otherPerson!.isVerified,
                    lastMessage: project.lastMessage,
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

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<ProjectCubit>(),
                              ),
                              BlocProvider(
                                create: (_) => di.sl<MessageCubit>()
                                  ..loadMessages(project.id),
                              ),
                              BlocProvider.value(
                                value: context.read<PersonCubit>(),
                              ),
                            ],
                            child: ConversationPage(
                              project: project,
                            ),
                          ),
                        ),
                      );

                      if (context.mounted) {
                        context.read<ProjectCubit>().loadProjects();
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
