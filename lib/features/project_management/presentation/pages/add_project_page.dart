import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final _titleController = TextEditingController();

  final List<String> _selectedParticipants = [];
  String? _ownerId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _toggleParticipant(Person person) {
    setState(() {
      if (_selectedParticipants.contains(person.id)) {
        _selectedParticipants.remove(person.id);
      } else {
        _selectedParticipants.add(person.id);
      }
    });
  }

  void _selectOwner(String? id) {
    setState(() {
      _ownerId = id;

      // Remove owner from contacts if already selected
      _selectedParticipants.remove(id);
    });
  }

  void _createProject() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat name is required'),
        ),
      );
      return;
    }

    if (_ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select who you are'),
        ),
      );
      return;
    }

    if (_selectedParticipants.isEmpty || _ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one contact'),
        ),
      );
      return;
    }

    context.read<ProjectCubit>().createProject(
      title: title,
      ownerId: _ownerId!,
      participants: [
        _ownerId!,
        ..._selectedParticipants,
      ],
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Chat Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                if (state is! PersonLoaded) {
                  return const SizedBox();
                }

                return DropdownButtonFormField<String>(
                  value: _ownerId,
                  decoration: const InputDecoration(
                    labelText: 'You are',
                    border: OutlineInputBorder(),
                  ),
                  items: state.persons.map((person) {
                    return DropdownMenuItem(
                      value: person.id,
                      child: Text(person.name),
                    );
                  }).toList(),
                  onChanged: _selectOwner,
                );
              },
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Contacts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<PersonCubit, PersonState>(
                builder: (context, state) {
                  if (state is PersonLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is PersonLoaded) {
                    return ListView.builder(
                      itemCount: state.persons.length,
                      itemBuilder: (context, index) {
                        final person = state.persons[index];

                        if (person.id == _ownerId) {
                          return const SizedBox.shrink();
                        }

                        final selected = _selectedParticipants.contains(
                          person.id,
                        );

                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) => _toggleParticipant(person),
                          title: Text(person.name),
                          subtitle:
                              person.bio == null ? null : Text(person.bio!),
                          secondary: person.isVerified
                              ? const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                )
                              : null,
                        );
                      },
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _createProject,
                child: const Text(
                  'Create Chat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
