import '../../domain/entities/project.dart';

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.createdAt,
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
      participantIds: List<String>.from(json['participantIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'participantIds': participantIds,
    };
  }

  factory ProjectModel.fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      title: project.title,
      createdAt: project.createdAt,
      participantIds: project.participantIds,
    );
  }
}
