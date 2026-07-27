import 'package:equatable/equatable.dart';

class Person extends Equatable {
  final String id;
  final String name;
  final String? avatarPath;
  final String? bio;
  final bool isVerified;

  const Person({
    required this.id,
    required this.name,
    this.avatarPath,
    this.bio,
    this.isVerified = false,
  });

  Person copyWith({
    String? id,
    String? name,
    String? avatarPath,
    String? bio,
    bool? isVerified,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarPath,
        bio,
        isVerified,
      ];
}
