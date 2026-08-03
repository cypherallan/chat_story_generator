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
  const ProjectsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ProjectsListBody();
  }
}

class _ProjectsListBody extends StatelessWidget {
  const _ProjectsListBody();

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

                  final otherPersonId = project.participantIds.firstWhere(
                    (id) => id != project.ownerId,
                    orElse: () => project.ownerId,
                  );

                  final Person otherPerson = personState.persons.firstWhere(
                    (p) => p.id == otherPersonId,
                  );

                  final chat = ChatListItem(
                    project: project,
                    chatName: otherPerson.name,
                    avatarPath: otherPerson.avatarPath,
                    verified: otherPerson.isVerified,
                    lastMessage: project.lastMessage,
                    lastMessageTime: project.lastMessageTime,
                    unreadCount: project.unreadCount,
                  );

                  return ChatListItemWidget(
                    chat: chat,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
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
