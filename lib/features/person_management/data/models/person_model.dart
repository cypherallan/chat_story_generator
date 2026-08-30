import '../../domain/entities/person.dart';

class PersonModel extends Person {
  const PersonModel({
    required super.id,
    required super.name,
    super.avatarPath,
    super.bio,
    super.isVerified,
    super.isOnline,
    super.lastSeen,
    super.isPinned,
    super.ownerId,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      isPinned: json['isPinned'] as bool? ?? false,
      ownerId: json['ownerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'bio': bio,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'isPinned': isPinned,
      'ownerId': ownerId,
    };
  }

  factory PersonModel.fromEntity(Person person) {
    return PersonModel(
      id: person.id,
      name: person.name,
      avatarPath: person.avatarPath,
      bio: person.bio,
      isVerified: person.isVerified,
      isOnline: person.isOnline,
      lastSeen: person.lastSeen,
      isPinned: person.isPinned,
      ownerId: person.ownerId,
    );
  }
}
