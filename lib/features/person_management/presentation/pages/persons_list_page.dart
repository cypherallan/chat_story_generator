import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'edit_participant_page.dart';
import '../../../../injection_container.dart' as di;
import '../cubit/person_cubit.dart';
import '../widgets/person_card.dart';
import 'add_participant_page.dart';

import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../conversations/presentation/pages/conversation_page.dart';

class PersonsListPage extends StatelessWidget {
  final bool selectionMode;

  const PersonsListPage({
    super.key,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: context.read<PersonCubit>(),
        ),
        BlocProvider.value(
          value: context.read<ProjectCubit>(),
        ),
      ],
      child: _PersonsListView(
        selectionMode: selectionMode,
      ),
    );
  }
}

class _PersonsListView extends StatefulWidget {
  final bool selectionMode;

  const _PersonsListView({
    required this.selectionMode,
  });

  @override
  State<_PersonsListView> createState() => _PersonsListViewState();
}

class _PersonsListViewState extends State<_PersonsListView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  Future<String?> _selectOwner(
    BuildContext context,
    String contactId,
  ) async {
    final state = context.read<PersonCubit>().state;

    if (state is! PersonLoaded) {
      return null;
    }

    final owners = state.persons.where((p) => p.id != contactId).toList();

    return showModalBottomSheet<String>(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                "You are",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...owners.map(
                (person) => ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      person.name[0].toUpperCase(),
                    ),
                  ),
                  title: Text(person.name),
                  onTap: () {
                    Navigator.pop(context, person.id);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select contact"),
            BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                if (state is PersonLoaded) {
                  return Text(
                    "${state.persons.length} contacts",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 18),
          Icon(Icons.more_vert),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // CONTACTS LIST
          Expanded(
            child: BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                if (state is PersonLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is PersonError) {
                  return Center(
                    child: Text(state.message),
                  );
                }

                if (state is PersonLoaded) {
                  final filteredPersons = state.persons.where((person) {
                    return person.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  filteredPersons.sort(
                    (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                  );

                  if (filteredPersons.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Contacts found.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = filteredPersons[index];

                      return PersonCard(
                        person: person,
                        onMessage: () async {
                          final senderId = await _selectOwner(
                            context,
                            person.id,
                          );

                          if (senderId == null) return;

                          final project = await context
                              .read<ProjectCubit>()
                              .openOrCreatePrivateChat(
                                ownerId: senderId,
                                contactId: person.id,
                                contactName: person.name,
                              );

                          if (!mounted) return;

                          await context.read<ProjectCubit>().loadProjects();

                          Navigator.push(
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
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<PersonCubit>(),
                                child: EditParticipantPage(
                                  person: person,
                                ),
                              ),
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Delete Contact'),
                                content: Text(
                                  'Are you sure you want to delete ${person.name}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true && context.mounted) {
                            context.read<PersonCubit>().removePerson(person.id);
                          }
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<PersonCubit>(),
                child: const AddParticipantPage(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
