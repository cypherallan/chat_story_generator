import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/firebase_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/person.dart';
import '../../domain/usecases/add_person.dart';
import '../../domain/usecases/delete_person.dart';
import '../../domain/usecases/get_persons.dart';
import '../../domain/usecases/update_person.dart';
part 'person_state.dart';

class PersonCubit extends Cubit<PersonState> {
  final GetPersons getPersons;
  final AddPerson addPerson;
  final DeletePerson deletePerson;
  final FirebaseStorageService storageService;
  final UpdatePerson updatePerson;

  PersonCubit({
    required this.getPersons,
    required this.addPerson,
    required this.deletePerson,
    required this.updatePerson,
    required this.storageService,
  }) : super(PersonInitial());

  Future<void> editPerson(
    Person person, {
    String? newImagePath,
  }) async {
    emit(PersonLoading());

    var updatedPerson = person;

    if (newImagePath != null) {
      final imageUrl = await storageService.uploadParticipantImage(
        newImagePath,
        onProgress: (_) {},
      );

      if (imageUrl == null) {
        emit(const PersonError('Failed to upload image.'));
        return;
      }

      updatedPerson = person.copyWith(
        avatarPath: imageUrl,
      );
    }

    final result = await updatePerson(updatedPerson);

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (_) => loadPersons(),
    );
  }

  Future<void> loadPersons() async {
    emit(PersonLoading());

    final result = await getPersons(NoParams());

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (persons) => emit(PersonLoaded(List<Person>.from(persons))),
    );
  }

  Future<void> createPerson({
    required String name,
    String? avatarPath,
    String? bio,
    bool isVerified = false,
  }) async {
    emit(const PersonSaving(
      progress: 0,
      message: 'Preparing...',
    ));

    String? imageUrl;

    if (avatarPath != null) {
      imageUrl = await storageService.uploadParticipantImage(
        avatarPath,
        onProgress: (progress) {
          emit(
            PersonSaving(
              progress: progress,
              message:
                  'Uploading image... ${(progress * 100).toStringAsFixed(0)}%',
            ),
          );
        },
      );

      if (imageUrl == null) {
        emit(const PersonError('Failed to upload image.'));
        return;
      }
    }

    emit(
      const PersonSaving(
        progress: 1,
        message: 'Saving participant...',
      ),
    );

    final person = Person(
      id: const Uuid().v4(),
      name: name,
      avatarPath: imageUrl,
      bio: bio,
      isVerified: isVerified,
    );

    final result = await addPerson(person);

    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (_) async {
        emit(PersonSaved());
        await loadPersons();
      },
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

  Future<void> setPersonOnline(String personId) async {
    if (state is! PersonLoaded) return;

    final persons = List<Person>.from((state as PersonLoaded).persons);

    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) return;

    final updated = persons[index].copyWith(
      isOnline: true,
    );

    persons[index] = updated;

    emit(PersonLoaded(persons));

    await updatePerson(updated);
  }

  Future<void> setPersonOffline(String personId) async {
    if (state is! PersonLoaded) return;

    final persons = List<Person>.from((state as PersonLoaded).persons);

    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) return;

    final updated = persons[index].copyWith(
      isOnline: false,
      lastSeen: DateTime.now(),
    );

    persons[index] = updated;

    emit(PersonLoaded(persons));

    await updatePerson(updated);
  }
}
