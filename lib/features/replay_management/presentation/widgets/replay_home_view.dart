import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';
import 'replay_home_chat_list.dart';

class ReplayHomeView extends StatelessWidget {
  final void Function(dynamic project) onChatTap;

  const ReplayHomeView({
    super.key,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhatsApp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Icon(Icons.camera_alt_outlined),
          SizedBox(width: 18),
          Icon(Icons.search),
          SizedBox(width: 18),
          Icon(Icons.more_vert),
          SizedBox(width: 8),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Chats'),
            Tab(text: 'Updates'),
            Tab(text: 'Communities'),
            Tab(text: 'Calls'),
          ],
        ),
      ),
      body: BlocBuilder<ProjectCubit, ProjectState>(
        builder: (context, projectState) {
          if (projectState is ProjectLoading ||
              projectState is ProjectInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (projectState is ProjectError) {
            return Center(
              child: Text(projectState.message),
            );
          }

          if (projectState is! ProjectLoaded) {
            return const SizedBox.shrink();
          }

          return BlocBuilder<PersonCubit, PersonState>(
            builder: (context, personState) {
              if (personState is PersonLoading ||
                  personState is PersonInitial) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (personState is PersonError) {
                return Center(
                  child: Text(personState.message),
                );
              }

              if (personState is! PersonLoaded) {
                return const SizedBox.shrink();
              }

              return TabBarView(
                children: [
                  ReplayHomeChatList(
                    projects: projectState.projects,
                    persons: personState.persons,
                    onChatTap: (project) {
                      onChatTap(project);
                    },
                  ),
                  const Center(
                    child: Text('Updates'),
                  ),
                  const Center(
                    child: Text('Communities'),
                  ),
                  const Center(
                    child: Text('Calls'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
