import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    required this.name,
    this.radius = 25,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;

    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('http')) {
        image = CachedNetworkImageProvider(imagePath!);
      } else {
        image = FileImage(File(imagePath!));
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundImage: image,
      child: image == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
