import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/person.dart';

class PersonAvatar extends StatelessWidget {
  final Person person;
  final double radius;

  const PersonAvatar({
    super.key,
    required this.person,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (person.avatarPath == null || person.avatarPath!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Text(
          person.name[0].toUpperCase(),
        ),
      );
    }

    if (person.avatarPath!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: person.avatarPath!,
        imageBuilder: (_, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (_, __) => CircleAvatar(
          radius: radius,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: radius,
          child: Text(
            person.name[0].toUpperCase(),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: FileImage(
        File(person.avatarPath!),
      ),
    );
  }
}
