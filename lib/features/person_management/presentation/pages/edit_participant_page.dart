import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/person.dart';
import '../cubit/person_cubit.dart';

class EditParticipantPage extends StatefulWidget {
  final Person person;

  const EditParticipantPage({
    super.key,
    required this.person,
  });

  @override
  State<EditParticipantPage> createState() => _EditParticipantPageState();
}

class _EditParticipantPageState extends State<EditParticipantPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.person.name,
    );

    _bioController = TextEditingController(
      text: widget.person.bio ?? '',
    );

    _isVerified = widget.person.isVerified;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
        ),
      );
      return;
    }

    final updatedPerson = Person(
      id: widget.person.id,
      name: name,
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      isVerified: _isVerified,
      avatarPath: widget.person.avatarPath,
    );

    await context.read<PersonCubit>().editPerson(
          updatedPerson,
          newImagePath: _imagePath,
        );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;

    if (_imagePath != null) {
      avatarImage = FileImage(
        File(_imagePath!),
      );
    } else if (widget.person.avatarPath != null &&
        widget.person.avatarPath!.startsWith('http')) {
      avatarImage = NetworkImage(
        widget.person.avatarPath!,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Participant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        widget.person.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio / About',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Verified Badge'),
              subtitle: const Text(
                'Show blue checkmark',
              ),
              value: _isVerified,
              onChanged: (value) {
                setState(() {
                  _isVerified = value;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saveChanges,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
