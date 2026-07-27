import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/person.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PersonCard({
    super.key,
    required this.person,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (person.avatarPath == null || person.avatarPath!.isEmpty) {
      avatar = CircleAvatar(
        child: Text(person.name[0].toUpperCase()),
      );
    } else if (person.avatarPath!.startsWith('http')) {
      avatar = CachedNetworkImage(
        imageUrl: person.avatarPath!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => const CircleAvatar(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          child: Text(person.name[0].toUpperCase()),
        ),
      );
    } else {
      avatar = CircleAvatar(
        backgroundImage: FileImage(
          File(person.avatarPath!),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: avatar,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                person.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (person.isVerified)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
          ],
        ),
        subtitle: Text(
          person.bio ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
