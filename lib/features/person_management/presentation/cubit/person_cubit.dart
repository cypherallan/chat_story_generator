import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/person.dart';
import '../../domain/usecases/add_person.dart';
import '../../domain/usecases/delete_person.dart';
import '../../domain/usecases/get_persons.dart';

part 'person_state.dart';

class PersonCubit extends Cubit<PersonState> {
  final GetPersons getPersons;
  final AddPerson addPerson;
  final DeletePerson deletePerson;

  PersonCubit({
    required this.getPersons,
    required this.addPerson,
    required this.deletePerson,
  }) : super(PersonInitial());

  Future<void> loadPersons() async {
    emit(PersonLoading());

    final result = await getPersons(NoParams());

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(PersonLoaded(persons)),
    );
  }

  Future<void> createPerson({
    required String name,
    String? avatarPath,
    String? bio,
    bool isVerified = false,
  }) async {
    emit(PersonLoading());

    final person = Person(
      id: const Uuid().v4(),
      name: name,
      avatarPath: avatarPath,
      bio: bio,
      isVerified: isVerified,
    );

    final result = await addPerson(person);

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (_) => loadPersons(),
    );
  }

  Future<void> removePerson(String id) async {
    emit(PersonLoading());

    final result = await deletePerson(id);

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (_) => loadPersons(),
    );
  }
}
