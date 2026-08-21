import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final String id;
  final String name;
  final String? avatarPath;
  final String? bio;
  final bool isVerified;

  final bool isOnline;
  final DateTime? lastSeen;

  // Pinned contacts appear first in owner selection.
  final bool isPinned;

  const Person({
    required this.id,
    required this.name,
    this.avatarPath,
    this.bio,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.isPinned = false,
  });

  Person copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? bio,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isPinned,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarPath,
        bio,
        isVerified,
        isOnline,
        lastSeen,
        isPinned,
      ];
}
