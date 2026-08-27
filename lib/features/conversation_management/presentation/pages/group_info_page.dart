import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../group_management/domain/entities/project.dart';
import '../../../group_management/presentation/cubit/group_cubit.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/pages/persons_list_page.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/presentation/widgets/person_avatar.dart';

class GroupInfoPage extends StatefulWidget {
  final Project project;
  final List<Person> persons;
  const GroupInfoPage(
      {super.key, required this.project, required this.persons});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late TextEditingController _nameController;
  late Project _project;
  File? _newImage;
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;
  bool _savedSuccessfully = false;
  bool _addingParticipant = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _nameController = TextEditingController(text: _project.title);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changeImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newImage = File(picked.path));
  }

  Future<void> _addParticipant(String personId) async {
    if (_project.participantIds.contains(personId)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Already in group')));
      return;
    }

    final newIds = [..._project.participantIds, personId];
    final updated = _project.copyWith(participantIds: newIds);

    // optimistic UI update — shows instantly
    setState(() {
      _project = updated;
      _addingParticipant = true;
    });

    try {
      await context.read<GroupCubit>().editProject(updated);
      // don't check state — Firestore write already succeeded if no exception
      if (!mounted) return;
      setState(() => _addingParticipant = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Participant added')));
    } catch (e) {
      // rollback on real failure
      if (!mounted) return;
      setState(() {
        _project = widget.project;
        _addingParticipant = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name cannot be empty')));
      return;
    }
    setState(() => _saving = true);
    final updated = _project.copyWith(
        title: name,
        groupImagePath: _newImage?.path ?? _project.groupImagePath);
    await context.read<GroupCubit>().editProject(updated);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _savedSuccessfully = true;
      _project = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.persons
        .where((p) => _project.participantIds.contains(p.id))
        .toList()
      ..sort((a, b) {
        if (a.id == _project.ownerId) return -1;
        if (b.id == _project.ownerId) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Group Info')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _changeImage,
              child: Builder(
                builder: (_) {
                  ImageProvider? image;
                  if (_newImage != null) {
                    image = FileImage(_newImage!);
                  } else if (_project.groupImagePath != null &&
                      _project.groupImagePath!.isNotEmpty) {
                    if (_project.groupImagePath!.startsWith('http')) {
                      image = CachedNetworkImageProvider(
                        _project.groupImagePath!,
                      );
                    } else {
                      image = FileImage(
                        File(_project.groupImagePath!),
                      );
                    }
                  }
                  return CircleAvatar(
                    radius: 55,
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 25),
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Group Name', border: OutlineInputBorder())),
          const SizedBox(height: 30),
          Text('${members.length} participants',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...members.map((p) => ListTile(
                leading: PersonAvatar(person: p, radius: 22),
                title: Text(p.id == _project.ownerId ? 'You' : p.name),
                subtitle: p.bio == null || p.bio!.isEmpty
                    ? null
                    : Text(p.bio!,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              enabled: !_addingParticipant,
              leading: CircleAvatar(
                backgroundColor: const Color(0xff25D366),
                child: _addingParticipant
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.person_add, color: Colors.white),
              ),
              title: const Text("Add participants"),
              onTap: () async {
                final personId = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<PersonCubit>()),
                        BlocProvider.value(value: context.read<GroupCubit>()),
                      ],
                      child: PersonsListPage(
                          addToGroupMode: true,
                          excludedIds: _project.participantIds,
                          currentPersonId: _project.ownerId),
                    ),
                  ),
                );
                if (personId == null) return;
                await _addParticipant(personId);
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed:
                      _saving || _savedSuccessfully ? null : _saveChanges,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_savedSuccessfully
                          ? 'Changes Saved Successfully'
                          : 'Save Changes'))),
        ],
      ),
    );
  }
}
