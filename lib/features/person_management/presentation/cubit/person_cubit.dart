import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/firebase_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/person.dart';
import '../../domain/usecases/add_person.dart';
import '../../domain/usecases/delete_person.dart';
import '../../domain/usecases/get_persons.dart';
import '../../domain/usecases/get_persons_by_owner.dart';
import '../../domain/usecases/update_person.dart';
part 'person_state.dart';

class PersonCubit extends Cubit<PersonState> {
  final GetPersons getPersons;
  final GetPersonsByOwner getPersonsByOwner;
  final AddPerson addPerson;
  final DeletePerson deletePerson;
  final FirebaseStorageService storageService;
  final UpdatePerson updatePerson;

  PersonCubit({
    required this.getPersons,
    required this.getPersonsByOwner,
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
      if (isClosed) return;
      if (imageUrl == null) {
        emit(const PersonError('Failed to upload image.'));
        return;
      }
      updatedPerson = person.copyWith(avatarPath: imageUrl);
    }
    final result = await updatePerson(updatedPerson);
    if (isClosed) return;
    result.fold(
      (failure) => emit(PersonError(failure.message)),
      (_) => loadPersons(),
    );
  }

  Future<void> togglePersonPin(String personId) async {
    if (state is! PersonLoaded) return;
    final persons = List<Person>.from((state as PersonLoaded).persons);
    final index = persons.indexWhere((person) => person.id == personId);
    if (index == -1) return;
    final person = persons[index];
    final updatedPerson = person.copyWith(isPinned: !person.isPinned);
    persons[index] = updatedPerson;
    emit(PersonLoaded(persons));
    final result = await updatePerson(updatedPerson);
    result.fold((failure) {
      loadPersons();
    }, (_) {});
  }

  Future<void> loadPersons() async {
    if (isClosed) return;
    emit(PersonLoading());
    final result = await getPersons(NoParams());
    if (isClosed) return;
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(PersonError(failure.message));
      },
      (persons) {
        if (isClosed) return;
        emit(PersonLoaded(List<Person>.from(persons)));
      },
    );
  }

  Future<void> loadPersonsByOwner(String ownerId) async {
    if (isClosed) return;
    emit(PersonLoading());
    final result = await getPersonsByOwner(ownerId);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(PersonError(failure.message));
      },
      (persons) {
        if (isClosed) return;
        emit(PersonLoaded(List<Person>.from(persons)));
      },
    );
  }

  Future<void> createPerson({
    required String name,
    String? avatarPath,
    String? bio,
    bool isVerified = false,
    String? ownerId,
  }) async {
    emit(const PersonSaving(progress: 0, message: 'Preparing...'));
    String? imageUrl;
    if (avatarPath != null) {
      imageUrl = await storageService.uploadParticipantImage(
        avatarPath,
        onProgress: (progress) {
          if (isClosed) return;
          emit(PersonSaving(
              progress: progress,
              message:
                  'Uploading image... ${(progress * 100).toStringAsFixed(0)}%'));
        },
      );
      if (isClosed) return;
      if (imageUrl == null) {
        emit(const PersonError('Failed to upload image.'));
        return;
      }
    }
    emit(const PersonSaving(progress: 1, message: 'Saving participant...'));
    final person = Person(
      id: const Uuid().v4(),
      name: name,
      avatarPath: imageUrl,
      bio: bio,
      isVerified: isVerified,
      ownerId: ownerId,
    );
    final result = await addPerson(person);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(PersonError(failure.message));
      },
      (_) async {
        if (isClosed) return;
        emit(PersonSaved());
        await loadPersons();
      },
    );
  }

  Future<void> removePerson(String id) async {
    emit(PersonLoading());
    final result = await deletePerson(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (isClosed) return;
        emit(PersonError(failure.message));
      },
      (_) {
        if (isClosed) return;
        loadPersons();
      },
    );
  }

  Future<void> setPersonOnline(String personId) async {
    if (state is! PersonLoaded) return;
    final persons = List<Person>.from((state as PersonLoaded).persons);
    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) return;
    final updated = persons[index].copyWith(isOnline: true);
    persons[index] = updated;
    emit(PersonLoaded(persons));
    await updatePerson(updated);
  }

  Future<void> setPersonOffline(String personId) async {
    if (state is! PersonLoaded) return;
    final persons = List<Person>.from((state as PersonLoaded).persons);
    final index = persons.indexWhere((p) => p.id == personId);
    if (index == -1) return;
    final updated =
        persons[index].copyWith(isOnline: false, lastSeen: DateTime.now());
    persons[index] = updated;
    emit(PersonLoaded(persons));
    await updatePerson(updated);
  }
}
