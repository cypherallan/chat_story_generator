import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final String id;
  final String name;
  final String? avatarPath;
  final String? bio;
  final bool isVerified;

  // NEW
  final bool isOnline;
  final DateTime? lastSeen;

  const Person({
    required this.id,
    required this.name,
    this.avatarPath,
    this.bio,
    this.isVerified = false,

    // NEW
    this.isOnline = false,
    this.lastSeen,
  });

  Person copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? bio,
    bool? isVerified,

    // NEW
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
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
      ];
}
