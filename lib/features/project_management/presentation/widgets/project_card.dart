import 'package:flutter/material.dart';

import '../../domain/entities/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.folder),
        ),
        title: Text(project.title),
        subtitle: Text(
          '${project.participantIds.length} participant(s)',
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
