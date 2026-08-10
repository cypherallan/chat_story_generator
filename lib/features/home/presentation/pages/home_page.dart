import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;

import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../project_management/presentation/pages/add_project_page.dart';
import '../../../project_management/presentation/pages/projects_list_widget.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/presentation/pages/persons_list_page.dart';

import '../../../auth/presentation/pages/profile_page.dart';
import '../../../../core/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> selectedChatIds = {};

  bool get isSelectionMode => selectedChatIds.isNotEmpty;

  void toggleChatSelection(String id) {
    setState(() {
      if (selectedChatIds.contains(id)) {
        selectedChatIds.remove(id);
      } else {
        selectedChatIds.add(id);
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedChatIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<ProjectCubit>()..loadProjects(),
        ),
        BlocProvider(
          create: (_) => di.sl<PersonCubit>()..loadPersons(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                title: isSelectionMode
                    ? Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: clearSelection,
                          ),
                          Text(selectedChatIds.length.toString()),
                        ],
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfilePage(
                                authService: di.sl<AuthService>(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "WhatsApp",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                actions: isSelectionMode
                    ? [
                        IconButton(
                          icon: const Icon(Icons.push_pin_outlined),
                          onPressed: () {
                            // TODO: pin selected chats
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete chat'),
                                content: Text(
                                  selectedChatIds.length == 1
                                      ? 'Delete selected chat?'
                                      : 'Delete ${selectedChatIds.length} chats?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true) return;

                            final cubit = context.read<ProjectCubit>();

                            await cubit.removeProjects(
                              selectedChatIds.toList(),
                            );

                            clearSelection();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_off_outlined),
                          onPressed: () {
                            // TODO: mute selected chats
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () {
                            // TODO: archive selected chats
                          },
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "more",
                              child: Text("More"),
                            ),
                          ],
                        ),
                      ]
                    : [
                        const Icon(Icons.camera_alt_outlined),
                        const SizedBox(width: 18),
                        const Icon(Icons.search),
                        const SizedBox(width: 18),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'contacts':
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
                                      child: const PersonsListPage(),
                                    ),
                                  ),
                                );
                                break;

                              case 'settings':
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'new_group',
                              child: Text('New group'),
                            ),
                            PopupMenuItem(
                              value: 'new_broadcast',
                              child: Text('New broadcast'),
                            ),
                            PopupMenuItem(
                              value: 'contacts',
                              child: Text('Contacts'),
                            ),
                            PopupMenuItem(
                              value: 'settings',
                              child: Text('Settings'),
                            ),
                          ],
                        ),
                      ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: "Chats"),
                    Tab(text: "Updates"),
                    Tab(text: "Communities"),
                    Tab(text: "Calls"),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  ProjectsListWidget(
                    selectedChatIds: selectedChatIds,
                    onChatSelected: toggleChatSelection,
                  ),
                  const Center(child: Text("Updates")),
                  const Center(child: Text("Communities")),
                  const Center(child: Text("Calls")),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.chat),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(
                            value: context.read<ProjectCubit>(),
                          ),
                          BlocProvider.value(
                            value: context.read<PersonCubit>(),
                          ),
                        ],
                        child: const AddProjectPage(),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
