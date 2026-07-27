import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/firebase_storage_service.dart';
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
  final FirebaseStorageService storageService;

  PersonCubit({
    required this.getPersons,
    required this.addPerson,
    required this.deletePerson,
    required this.storageService,
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
}
