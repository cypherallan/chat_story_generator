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
    final hasNetworkImage = imagePath != null &&
        imagePath!.isNotEmpty &&
        imagePath!.startsWith('http');

    final fallbackLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (!hasNetworkImage) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          fallbackLetter,
          style: TextStyle(
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imagePath!,
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        );
      },
      placeholder: (context, url) {
        return CircleAvatar(
          radius: radius,
          child: Text(
            fallbackLetter,
            style: TextStyle(
              fontSize: radius * 0.8,
            ),
          ),
        );
      },
      errorWidget: (context, url, error) {
        return CircleAvatar(
          radius: radius,
          child: Text(
            fallbackLetter,
            style: TextStyle(
              fontSize: radius * 0.8,
            ),
          ),
        );
      },
    );
  }
}
