import 'dart:io';

import 'package:flutter/material.dart';

class ImagePreviewPage extends StatelessWidget {
  final File image;

  const ImagePreviewPage({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(image),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff25D366),
        onPressed: () {
          Navigator.pop(context, image);
        },
        child: const Icon(Icons.send),
      ),
    );
  }
}
