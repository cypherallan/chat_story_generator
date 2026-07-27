import 'package:flutter/material.dart';
import '../../../person_management/presentation/pages/persons_list_page.dart';
import '../../../project_management/presentation/pages/projects_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Story Generator'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _HomeCard(
              icon: Icons.chat,
              title: 'Chats',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProjectsListPage(),
                  ),
                );
              },
            ),
            _HomeCard(
              icon: Icons.people,
              title: 'People',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PersonsListPage(),
                  ),
                );
              },
            ),
            _HomeCard(
              icon: Icons.folder_copy,
              title: 'Drafts',
              onTap: () {},
            ),
            _HomeCard(
              icon: Icons.video_library,
              title: 'Exports',
              onTap: () {},
            ),
            _HomeCard(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
