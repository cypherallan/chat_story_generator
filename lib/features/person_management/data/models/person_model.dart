import '../../domain/entities/person.dart';

class PersonModel extends Person {
  const PersonModel({
    required super.id,
    required super.name,
    super.avatarPath,
    super.bio,
    super.isVerified,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'bio': bio,
      'isVerified': isVerified,
    };
  }

  factory PersonModel.fromEntity(Person person) {
    return PersonModel(
      id: person.id,
      name: person.name,
      avatarPath: person.avatarPath,
      bio: person.bio,
      isVerified: person.isVerified,
    );
  }
}