import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/project.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<Project>>> getProjects();

  Future<Either<Failure, Project>> addProject(Project project);

  Future<Either<Failure, void>> deleteProject(String id);

  Future<Either<Failure, Project>> updateProject(Project project);
}
