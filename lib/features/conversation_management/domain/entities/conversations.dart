import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? title,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        participantIds,
        createdAt,
        updatedAt,
      ];
}
