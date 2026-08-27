import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../project_management/presentation/pages/add_group_page.dart';
import '../../../project_management/presentation/pages/projects_list_widget.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_state.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/presentation/pages/persons_list_page.dart';
import 'package:uuid/uuid.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../person_management/domain/entities/person.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<String> selectedChatIds = {};

  String? _currentPersonId;

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

  Person? _getCurrentPerson(List<Person> persons) {
    if (persons.isEmpty) {
      return null;
    }

    if (_currentPersonId != null) {
      for (final person in persons) {
        if (person.id == _currentPersonId) {
          return person;
        }
      }
    }

    final pinnedPersons = persons.where((person) => person.isPinned).toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            ),
      );

    if (pinnedPersons.isNotEmpty) {
      return pinnedPersons.first;
    }

    return persons.first;
  }

  void _selectCurrentPerson(
    BuildContext context,
    List<Person> persons,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final sortedPersons = List<Person>.from(persons)
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }

            return a.name.toLowerCase().compareTo(
                  b.name.toLowerCase(),
                );
          });

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Who are you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...sortedPersons.map(
                (person) {
                  final isSelected = person.id == _currentPersonId;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        person.name.isNotEmpty
                            ? person.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(person.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                              person.isPinned ? 'Unpin contact' : 'Pin contact',
                          icon: Icon(
                            person.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: person.isPinned ? Colors.blue : null,
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext);

                            context
                                .read<PersonCubit>()
                                .togglePersonPin(person.id);

                            Future.microtask(() {
                              if (!mounted) return;

                              final personState =
                                  context.read<PersonCubit>().state;

                              if (personState is PersonLoaded) {
                                _selectCurrentPerson(
                                  context,
                                  personState.persons,
                                );
                              }
                            });
                          },
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                          ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _currentPersonId = person.id;
                      });

                      Navigator.pop(sheetContext);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
        BlocProvider(
          create: (_) => di.sl<SimulatedNotificationCubit>(),
        ),
        BlocProvider(
          create: (_) => di.sl<MessageCubit>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocListener<SimulatedNotificationCubit,
              SimulatedNotificationState>(
            listener: (context, state) {
              if (!state.visible || state.notification == null) {
                return;
              }
            },
            child: DefaultTabController(
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
                      : BlocBuilder<PersonCubit, PersonState>(
                          builder: (context, personState) {
                            if (personState is! PersonLoaded) {
                              return const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            final currentPerson = _getCurrentPerson(
                              personState.persons,
                            );

                            if (currentPerson == null) {
                              return const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }

                            if (_currentPersonId == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;

                                if (_currentPersonId == null) {
                                  setState(() {
                                    _currentPersonId = currentPerson.id;
                                  });
                                }
                              });
                            }

                            return GestureDetector(
                              onTap: () {
                                _selectCurrentPerson(
                                  context,
                                  personState.persons,
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'WhatsApp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        currentPerson.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  actions: isSelectionMode
                      ? [
                          IconButton(
                            icon: const Icon(Icons.push_pin_outlined),
                            onPressed: () {},
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
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.archive_outlined),
                            onPressed: () {},
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
                            onSelected: (value) async {
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
                                        child: PersonsListPage(
                                          currentPersonId: _currentPersonId!,
                                        ),
                                      ),
                                    ),
                                  );
                                  break;

                                case 'settings':
                                  break;

                                case 'simulate_notification':
                                  const projectId =
                                      '2759ca44-dec8-4706-b3dd-0b1b7c55cd95';

                                  const senderId =
                                      'f3bc2f12-7fe7-4690-9e41-f8e2b0bc6e25';

                                  const messageText =
                                      'Bro, did you see that goal? 😂';

                                  final personState =
                                      context.read<PersonCubit>().state;

                                  if (personState is! PersonLoaded) {
                                    return;
                                  }

                                  final sender = personState.persons.firstWhere(
                                    (person) => person.id == senderId,
                                  );

                                  final messageCubit =
                                      context.read<MessageCubit>();

                                  await messageCubit.createMessage(
                                    projectId: projectId,
                                    senderId: sender.id,
                                    senderName: sender.name,
                                    text: messageText,
                                  );

                                  if (!context.mounted) return;

                                  context
                                      .read<SimulatedNotificationCubit>()
                                      .showNotification(
                                        projectId: projectId,
                                        messageId: const Uuid().v4(),
                                        senderId: sender.id,
                                        senderName: sender.name,
                                        senderAvatarPath: sender.avatarPath,
                                        messageText: messageText,
                                      );

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
                              PopupMenuItem(
                                value: 'simulate_notification',
                                child: Text('Simulate incoming message'),
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
                body: BlocListener<MessageCubit, MessageState>(
                  listener: (context, messageState) {
                    if (messageState is MessageLoaded) {
                      context.read<ProjectCubit>().loadProjects();
                    }
                  },
                  child: TabBarView(
                    children: [
                      ProjectsListWidget(
                        selectedChatIds: selectedChatIds,
                        onChatSelected: toggleChatSelection,
                        currentPersonId: _currentPersonId,
                      ),
                      const Center(child: Text("Updates")),
                      const Center(child: Text("Communities")),
                      const Center(child: Text("Calls")),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.chat),
                  onPressed: () async {
                    final newOwnerId = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(
                                value: context.read<ProjectCubit>()),
                            BlocProvider.value(
                                value: context.read<PersonCubit>()),
                          ],
                          child:
                              AddGroupPage(currentPersonId: _currentPersonId),
                        ),
                      ),
                    );
                    if (newOwnerId != null && newOwnerId != _currentPersonId) {
                      setState(() => _currentPersonId = newOwnerId);
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
