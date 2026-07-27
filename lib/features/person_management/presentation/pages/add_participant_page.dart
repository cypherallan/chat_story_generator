import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../cubit/person_cubit.dart';

class AddParticipantPage extends StatefulWidget {
  const AddParticipantPage({super.key});

  @override
  State<AddParticipantPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddParticipantPage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();
  String? _imagePath;
  bool _isVerified = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name is required'),
        ),
      );
      return;
    }

    await context.read<PersonCubit>().createPerson(
          name: name,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          avatarPath: _imagePath,
          isVerified: _isVerified,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Participant'),
      ),
      body: BlocConsumer<PersonCubit, PersonState>(
        listener: (context, state) {
          if (state is PersonSaved) {
            Navigator.pop(context);
          }

          if (state is PersonError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: state is PersonSaving ? null : _pickImage,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: _imagePath != null
                        ? FileImage(File(_imagePath!))
                        : null,
                    child: _imagePath == null
                        ? const Icon(Icons.camera_alt, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  enabled: state is! PersonSaving,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Cristiano Ronaldo',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioController,
                  enabled: state is! PersonSaving,
                  decoration: const InputDecoration(
                    labelText: 'Bio / About',
                    hintText: 'e.g. Footballer, 5x Ballon d\'Or winner',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Verified Badge'),
                  subtitle: const Text('Show blue checkmark'),
                  value: _isVerified,
                  onChanged: state is PersonSaving
                      ? null
                      : (v) => setState(() => _isVerified = v),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: state is PersonSaving ? null : _submit,
                    child: state is PersonSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Character',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
