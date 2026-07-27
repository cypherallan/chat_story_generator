import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/person.dart';
import '../repositories/person_repository.dart';

class GetPersons implements UseCase<List<Person>, NoParams> {
  final PersonRepository repository;
  GetPersons(this.repository);

  @override
  Future<Either<Failure, List<Person>>> call(NoParams params) async {
    return await repository.getPersons();
  }
}
