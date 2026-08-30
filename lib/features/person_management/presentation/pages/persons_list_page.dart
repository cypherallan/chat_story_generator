import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'edit_participant_page.dart';
import '../../../../injection_container.dart' as di;
import '../cubit/person_cubit.dart';
import '../widgets/person_card.dart';
import 'add_participant_page.dart';
import '../../../group_management/presentation/cubit/group_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../conversation_management/presentation/pages/conversation_page.dart';
import '../widgets/person_avatar.dart';

class PersonsListPage extends StatelessWidget {
  final bool selectionMode;
  final bool addToGroupMode;
  final List<String> excludedIds;
  final String currentPersonId;

  const PersonsListPage({
    super.key,
    this.selectionMode = false,
    this.addToGroupMode = false,
    this.excludedIds = const [],
    required this.currentPersonId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<PersonCubit>()),
        BlocProvider.value(value: context.read<GroupCubit>()),
      ],
      child: _PersonsListView(
        selectionMode: selectionMode,
        addToGroupMode: addToGroupMode,
        excludedIds: excludedIds,
        currentPersonId: currentPersonId,
      ),
    );
  }
}

class _PersonsListView extends StatefulWidget {
  final bool selectionMode;
  final bool addToGroupMode;
  final List<String> excludedIds;
  final String currentPersonId;

  const _PersonsListView({
    required this.selectionMode,
    required this.addToGroupMode,
    required this.excludedIds,
    required this.currentPersonId,
  });

  @override
  State<_PersonsListView> createState() => _PersonsListViewState();
}

class _PersonsListViewState extends State<_PersonsListView> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Don't filter the cubit, just make sure ALL is loaded for HomePage arrow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<PersonCubit>().state;
      if (state is! PersonLoaded || state.persons.isEmpty) {
        context.read<PersonCubit>().loadPersons();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddContact() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PersonCubit>(),
          child: AddParticipantPage(ownerId: widget.currentPersonId),
        ),
      ),
    );
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
                        fontSize: 12, fontWeight: FontWeight.normal),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: const [
          Icon(Icons.more_vert),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                if (!widget.selectionMode && !widget.addToGroupMode)
                  FilledButton.icon(
                    onPressed: _openAddContact,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text("Add contact"),
                  ),
                if (!widget.selectionMode && !widget.addToGroupMode)
                  const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: "Search contacts",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                if (state is PersonLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PersonError) {
                  return Center(child: Text(state.message));
                }
                if (state is PersonLoaded) {
                  final filteredPersons = state.persons.where((person) {
                    if (person.ownerId != widget.currentPersonId) return false;
                    if (person.id == widget.currentPersonId) return false;
                    if (widget.excludedIds.contains(person.id)) return false;
                    return person.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  filteredPersons.sort((a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                  if (filteredPersons.isEmpty) {
                    return const Center(child: Text('No Contacts found.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = filteredPersons[index];
                      if (widget.addToGroupMode) {
                        return ListTile(
                          leading: PersonAvatar(person: person, radius: 22),
                          title: Text(person.name),
                          subtitle:
                              person.bio == null ? null : Text(person.bio!),
                          trailing: FilledButton(
                            child: const Text("Add"),
                            onPressed: () => Navigator.pop(context, person.id),
                          ),
                        );
                      }
                      if (widget.selectionMode) {
                        final selected = _selectedIds.contains(person.id);
                        return CheckboxListTile(
                          value: selected,
                          secondary: PersonAvatar(person: person, radius: 20),
                          title: Text(person.name),
                          subtitle:
                              person.bio == null ? null : Text(person.bio!),
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                _selectedIds.remove(person.id);
                              } else {
                                _selectedIds.add(person.id);
                              }
                            });
                          },
                        );
                      }

                      return PersonCard(
                        person: person,
                        onMessage: () async {
                          final project = await context
                              .read<GroupCubit>()
                              .openOrCreatePrivateChat(
                                ownerId: widget.currentPersonId,
                                contactId: person.id,
                                contactName: person.name,
                              );
                          if (!mounted) return;
                          await context.read<GroupCubit>().loadProjects();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider.value(
                                      value: context.read<GroupCubit>()),
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
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<PersonCubit>(),
                                child: EditParticipantPage(person: person),
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
                                    'Are you sure you want to delete ${person.name}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
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
      floatingActionButton: widget.selectionMode
          ? FloatingActionButton(
              onPressed: () => Navigator.pop(context, _selectedIds),
              child: const Icon(Icons.check),
            )
          : null,
    );
  }
}
