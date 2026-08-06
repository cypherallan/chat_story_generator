import 'package:flutter/material.dart';
import '../../../media_management/presentation/pages/gallery_page.dart';
import 'dart:io';


class AttachmentSheet extends StatelessWidget {
  final ValueChanged<File> onImageSelected;

  const AttachmentSheet({
    super.key,
    required this.onImageSelected,
  });

  Widget _item({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: SizedBox(
        width: 85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 8,
          runSpacing: 20,
          children: [
            _item(
              icon: Icons.photo,
              color: Colors.purple,
              label: "Gallery",
              onTap: () async {
                final file = await Navigator.push<File>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GalleryPage(),
                  ),
                );

                if (file != null) {
                  onImageSelected(file);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            _item(
              icon: Icons.camera_alt,
              color: Colors.pink,
              label: "Camera",
              onTap: () {},
            ),
            _item(
              icon: Icons.location_on,
              color: Colors.green,
              label: "Location",
              onTap: () {},
            ),
            _item(
              icon: Icons.person,
              color: Colors.blue,
              label: "Contact",
              onTap: () {},
            ),
            _item(
              icon: Icons.insert_drive_file,
              color: Colors.indigo,
              label: "Document",
              onTap: () {},
            ),
            _item(
              icon: Icons.poll,
              color: Colors.orange,
              label: "Poll",
              onTap: () {},
            ),
            _item(
              icon: Icons.event,
              color: Colors.red,
              label: "Event",
              onTap: () {},
            ),
            _item(
              icon: Icons.auto_awesome,
              color: Colors.teal,
              label: "AI Images",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
