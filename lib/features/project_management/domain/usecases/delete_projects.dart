import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/project_repository.dart';

class DeleteProjects {
  final ProjectRepository repository;

  DeleteProjects(
    this.repository,
  );

  Future<Either<Failure, void>> call(
    List<String> ids,
  ) async {
    return await repository.deleteProjects(ids);
  }
}
