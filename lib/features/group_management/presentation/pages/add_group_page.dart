import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/domain/entities/person.dart';
import '../cubit/project_cubit.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddGroupPage extends StatefulWidget {
  final String? currentPersonId;
  const AddGroupPage({super.key, this.currentPersonId});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _titleController = TextEditingController();
  File? _groupImage;
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedParticipants = [];
  String? _ownerId;

  @override
  void initState() {
    super.initState();
    _ownerId = widget.currentPersonId;
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
      _selectedParticipants.remove(id);
    });
  }

  Future<void> _pickGroupImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _groupImage = File(pickedFile.path));
    }
  }

  Future<void> _createProject() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name is required')));
      return;
    }
    if (_ownerId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select who you are')));
      return;
    }
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one contact')));
      return;
    }

    await context.read<ProjectCubit>().createProject(
          title: title,
          ownerId: _ownerId!,
          participants: [_ownerId!, ..._selectedParticipants],
          groupImagePath: _groupImage?.path,
        );
    await context.read<ProjectCubit>().loadProjects();
    if (!mounted) return;
    Navigator.pop(context, _ownerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickGroupImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage:
                    _groupImage != null ? FileImage(_groupImage!) : null,
                child: _groupImage == null
                    ? const Icon(Icons.camera_alt, size: 35)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                  labelText: 'Group Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                if (state is! PersonLoaded) return const SizedBox();
                // sort You Are dropdown alphabetically too
                final sortedPersons = List<Person>.from(state.persons)
                  ..sort((a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                return DropdownButtonFormField<String>(
                  value: _ownerId,
                  decoration: const InputDecoration(
                      labelText: 'You are', border: OutlineInputBorder()),
                  items: sortedPersons.map((person) {
                    return DropdownMenuItem(
                        value: person.id, child: Text(person.name));
                  }).toList(),
                  onChanged: _selectOwner,
                );
              },
            ),
            const SizedBox(height: 24),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose Contacts',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<PersonCubit, PersonState>(
                builder: (context, state) {
                  if (state is PersonLoading)
                    return const Center(child: CircularProgressIndicator());
                  if (state is PersonLoaded) {
                    // alphabetical contacts
                    final filtered = state.persons
                        .where((p) => p.id != _ownerId)
                        .toList()
                      ..sort((a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final person = filtered[index];
                        final selected =
                            _selectedParticipants.contains(person.id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) => _toggleParticipant(person),
                          title: Text(person.name),
                          subtitle:
                              person.bio == null ? null : Text(person.bio!),
                          secondary: person.isVerified
                              ? const Icon(Icons.verified, color: Colors.blue)
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
                    child: const Text('Create Group'))),
          ],
        ),
      ),
    );
  }
}
