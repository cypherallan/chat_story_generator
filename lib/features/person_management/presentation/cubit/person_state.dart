part of 'person_cubit.dart';

abstract class PersonState extends Equatable {
  const PersonState();

  @override
  List<Object?> get props => [];
}

class PersonInitial extends PersonState {}

class PersonLoading extends PersonState {}

/// Loading while creating/updating a participant
class PersonSaving extends PersonState {
  final double progress; // 0.0 -> 1.0
  final String message;

  const PersonSaving({
    required this.progress,
    required this.message,
  });

  @override
  List<Object?> get props => [
        progress,
        message,
      ];
}

class PersonSaved extends PersonState {}

class PersonLoaded extends PersonState {
  final List<Person> persons;

  const PersonLoaded(this.persons);

  @override
  List<Object?> get props => [persons];
}

class PersonError extends PersonState {
  final String message;

  const PersonError(this.message);

  @override
  List<Object?> get props => [message];
}
