import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<String> participantIds;

  const Project({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.participantIds,
  });

  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<String>? participantIds,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        participantIds,
      ];
}
