import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/person.dart';
import '../repositories/person_repository.dart';

class AddPerson implements UseCase<Person, Person> {
  final PersonRepository repository;
  AddPerson(this.repository);

  @override
  Future<Either<Failure, Person>> call(Person person) async {
    return await repository.addPerson(person);
  }
}
