import 'package:dartz/dartz.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/person_repository.dart';
import '../datasources/person_firestore_data_source.dart';
import '../models/person_model.dart';

class PersonRepositoryImpl implements PersonRepository {
  final PersonFirestoreDataSource firestoreDataSource;

  PersonRepositoryImpl(this.firestoreDataSource);

  @override
  Future<Either<Failure, List<Person>>> getPersons() async {
    try {
      final persons = await firestoreDataSource.getPersons();
      return Right(persons);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, Person>> updatePerson(Person person) async {
    try {
      final model = PersonModel.fromEntity(person);

      final result = await firestoreDataSource.updatePerson(model);

      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, Person>> addPerson(Person person) async {
    try {
      final model = PersonModel.fromEntity(person);
      final result = await firestoreDataSource.addPerson(model);
      return Right(result);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> deletePerson(String id) async {
    try {
      await firestoreDataSource.deletePerson(id);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
