import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../cubit/project_cubit.dart';
import '../widgets/project_card.dart';
import 'add_project_page.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';

import '../../../conversations/presentation/pages/conversation_page.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';

class ProjectsListWidget extends StatelessWidget {
  const ProjectsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProjectCubit>()..loadProjects(),
      child: const _ProjectsListView(),
    );
  }
}

class _ProjectsListView extends StatelessWidget {
  const _ProjectsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: true,
      ),
      body: BlocBuilder<ProjectCubit, ProjectState>(
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
            if (state.projects.isEmpty) {
              return const Center(
                child: Text(
                  'No Chats yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              itemCount: state.projects.length,
              itemBuilder: (context, index) {
                final project = state.projects[index];

                return ProjectCard(
                  project: project,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (_) => di.sl<MessageCubit>()
                                ..loadMessages(project.id),
                            ),
                            BlocProvider(
                              create: (_) =>
                                  di.sl<PersonCubit>()..loadPersons(),
                            ),
                          ],
                          child: ConversationPage(
                            project: project,
                          ),
                        ),
                      ),
                    );
                  },
                  onDelete: () {
                    context.read<ProjectCubit>().removeProject(project.id);
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Chat'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<ProjectCubit>(),
                  ),
                  BlocProvider(
                    create: (_) => di.sl<PersonCubit>()..loadPersons(),
                  ),
                ],
                child: const AddProjectPage(),
              ),
            ),
          );
        },
      ),
    );
  }
}
