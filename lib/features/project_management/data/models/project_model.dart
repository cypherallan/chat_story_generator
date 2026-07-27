import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.ownerId,
    required super.participantIds,
  });

  factory ProjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'],
      ),
      ownerId: json['ownerId'] ?? '',
      participantIds: List<String>.from(
        json['participantIds'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'participantIds': participantIds,
    };
  }

  factory ProjectModel.fromEntity(
    Project project,
  ) {
    return ProjectModel(
      id: project.id,
      title: project.title,
      createdAt: project.createdAt,
      ownerId: project.ownerId,
      participantIds: project.participantIds,
    );
  }
}
