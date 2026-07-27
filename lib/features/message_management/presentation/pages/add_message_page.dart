import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';

import '../cubit/message_cubit.dart';

class AddMessagePage extends StatefulWidget {
  final String projectId;
  final List<String> participantIds;

  const AddMessagePage({
    super.key,
    required this.projectId,
    required this.participantIds,
  });

  @override
  State<AddMessagePage> createState() => _AddMessagePageState();
}

class _AddMessagePageState extends State<AddMessagePage> {
  final _messageController = TextEditingController();

  Person? _selectedPerson;

  @override
  void initState() {
    super.initState();

    context.read<PersonCubit>().loadPersons();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a sender'),
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message cannot be empty'),
        ),
      );
      return;
    }

    context.read<MessageCubit>().createMessage(
          projectId: widget.projectId,
          senderId: _selectedPerson!.id,
          text: _messageController.text.trim(),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                if (state is! PersonLoaded) {
                  return const CircularProgressIndicator();
                }

                final participants = state.persons
                    .where(
                      (person) => widget.participantIds.contains(person.id),
                    )
                    .toList();

                return DropdownButtonFormField<Person>(
                  value: _selectedPerson,
                  decoration: const InputDecoration(
                    labelText: 'Sender',
                    border: OutlineInputBorder(),
                  ),
                  items: participants.map((person) {
                    return DropdownMenuItem(
                      value: person,
                      child: Text(person.name),
                    );
                  }).toList(),
                  onChanged: (person) {
                    setState(() {
                      _selectedPerson = person;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Save Message',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
