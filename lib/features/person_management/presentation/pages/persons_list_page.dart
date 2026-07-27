import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'edit_participant_page.dart';
import '../../../../injection_container.dart' as di;
import '../cubit/person_cubit.dart';
import '../widgets/person_card.dart';
import 'add_participant_page.dart';

class PersonsListPage extends StatelessWidget {
  const PersonsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<PersonCubit>()..loadPersons(),
      child: const _PersonsListView(),
    );
  }
}

class _PersonsListView extends StatefulWidget {
  const _PersonsListView();

  @override
  State<_PersonsListView> createState() => _PersonsListViewState();
}

class _PersonsListViewState extends State<_PersonsListView> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search participants',
                hintText: 'e.g. Ronaldo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // PARTICIPANTS LIST
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

                  if (filteredPersons.isEmpty) {
                    return const Center(
                      child: Text(
                        'No participants found.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = filteredPersons[index];

                      return PersonCard(
                        person: person,
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
                                title: const Text('Delete Participant'),
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
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add),
        label: const Text('Participant'),
      ),
    );
  }
}
