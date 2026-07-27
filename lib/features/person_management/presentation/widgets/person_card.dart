import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/person.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onDelete;

  const PersonCard({
    super.key,
    required this.person,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: person.avatarPath != null
              ? FileImage(File(person.avatarPath!))
              : null,
          child: person.avatarPath == null
              ? Text(person.name[0].toUpperCase())
              : null,
        ),
        title: Row(
          children: [
            Text(person.name),
            if (person.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            ],
          ],
        ),
        subtitle: Text(
          person.bio ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
