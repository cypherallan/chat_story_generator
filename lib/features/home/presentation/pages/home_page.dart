import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;

import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../project_management/presentation/pages/add_project_page.dart';
import '../../../project_management/presentation/pages/projects_list_widget.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/presentation/pages/persons_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                title: const Text("WhatsApp"),
                actions: [
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
                          // TODO
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
              body: const TabBarView(
                children: [
                  ProjectsListWidget(),
                  Center(child: Text("Updates")),
                  Center(child: Text("Communities")),
                  Center(child: Text("Calls")),
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
