import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
import 'replay_home_chat_list.dart';

class ReplayHomeView extends StatelessWidget {
  final List<Project> projects;
  final String ownerId;
  final void Function(Project project) onChatTap;
  final String? highlightedProjectId;
  final bool isChatTapPressed;

  const ReplayHomeView({
    super.key,
    required this.projects,
    required this.ownerId,
    required this.onChatTap,
    this.highlightedProjectId,
    this.isChatTapPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (personState is PersonLoading || personState is PersonInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (personState is PersonError) {
          return Scaffold(
            body: Center(
              child: Text(personState.message),
            ),
          );
        }

        if (personState is! PersonLoaded) {
          return const Scaffold(
            body: SizedBox.shrink(),
          );
        }

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
          body: TabBarView(
            children: [
              ReplayHomeChatList(
                projects: projects,
                persons: personState.persons,
                ownerId: ownerId,
                onChatTap: onChatTap,
                highlightedProjectId: highlightedProjectId,
                isChatTapPressed: isChatTapPressed,
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
          ),
        );
      },
    );
  }
}
