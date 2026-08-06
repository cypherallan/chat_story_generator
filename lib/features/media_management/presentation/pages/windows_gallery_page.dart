import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class WindowsGalleryPage extends StatefulWidget {
  const WindowsGalleryPage({super.key});

  @override
  State<WindowsGalleryPage> createState() => _WindowsGalleryPageState();
}

class _WindowsGalleryPageState extends State<WindowsGalleryPage> {
  List<File> images = [];

  @override
  void initState() {
    super.initState();
    _pickFolder();
  }

  Future<void> _pickFolder() async {
    final folder = await FilePicker.getDirectoryPath();

    if (folder == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final files = Directory(folder)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
      final p = f.path.toLowerCase();
      return p.endsWith(".jpg") ||
          p.endsWith(".jpeg") ||
          p.endsWith(".png") ||
          p.endsWith(".webp");
    }).toList();

    if (!mounted) return;

    setState(() {
      images = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Gallery"),
      ),
      body: GridView.builder(
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => Navigator.pop(context, images[i]),
            child: Image.file(
              images[i],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
