import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class UpdateProject {
  final ProjectRepository repository;

  UpdateProject(this.repository);

  Future<Either<Failure, Project>> call(
    Project project,
  ) async {
    return await repository.updateProject(project);
  }
}
