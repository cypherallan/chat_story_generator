import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/pages/persons_list_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../person_management/presentation/widgets/person_avatar.dart';

class GroupInfoPage extends StatefulWidget {
  final Project project;
  final List<Person> persons;

  const GroupInfoPage({
    super.key,
    required this.project,
    required this.persons,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  late TextEditingController _nameController;

  File? _newImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.project.title,
    );
  }

  Future<void> _changeImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.persons
        .where(
          (person) => widget.project.participantIds.contains(person.id),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Group Info',
        ),
      ),
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
                  } else if (widget.project.groupImagePath != null &&
                      widget.project.groupImagePath!.isNotEmpty) {
                    if (widget.project.groupImagePath!.startsWith('http')) {
                      image = CachedNetworkImageProvider(
                        widget.project.groupImagePath!,
                      );
                    }
                  }

                  return CircleAvatar(
                    radius: 55,
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                          )
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
              labelText: 'Group Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            '${members.length} participants',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...members.map(
            (person) => ListTile(
              leading: PersonAvatar(
                person: person,
                radius: 22,
              ),
              title: Text(person.name),
              subtitle: person.bio == null || person.bio!.isEmpty
                  ? null
                  : Text(
                      person.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xff25D366),
                child: Icon(
                  Icons.person_add,
                  color: Colors.white,
                ),
              ),
              title: const Text("Add participants"),
              onTap: () async {
                final personId = await Navigator.push<String>(
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
                        addToGroupMode: true,
                        excludedIds: widget.project.participantIds,
                      ),
                    ),
                  ),
                );

                if (personId == null) return;

                // We'll connect this to ProjectCubit next.
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // Save changes
              },
              child: const Text("Save Changes"),
            ),
          ),
        ],
      ),
    );
  }
}
