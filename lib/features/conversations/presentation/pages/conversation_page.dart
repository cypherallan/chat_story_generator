import 'package:flutter/material.dart';

import '../../../project_management/domain/entities/project.dart';

class ConversationPage extends StatelessWidget {
  final Project project;

  const ConversationPage({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${project.participantIds.length} participants',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const Divider(height: 32),
            const Expanded(
              child: Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_comment),
        label: const Text('Add Message'),
      ),
    );
  }
}
