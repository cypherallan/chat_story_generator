import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;

  // The person who owns this chat ("Me")
  final String ownerId;

  final List<String> participantIds;

  const Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.ownerId,
    required this.participantIds,
  });

  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? ownerId,
    List<String>? participantIds,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        ownerId,
        participantIds,
      ];
}
