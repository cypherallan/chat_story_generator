import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/person.dart';
import '../repositories/person_repository.dart';

class GetPersonsByOwner implements UseCase<List<Person>, String> {
  final PersonRepository repository;
  GetPersonsByOwner(this.repository);

  @override
  Future<Either<Failure, List<Person>>> call(String ownerId) async {
    return await repository.getPersonsByOwner(ownerId);
  }
}
