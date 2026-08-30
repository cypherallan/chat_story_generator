import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';

abstract class PersonFirestoreDataSource {
  Future<List<PersonModel>> getPersons();
  Future<List<PersonModel>> getPersonsByOwner(String ownerId);
  Future<PersonModel> addPerson(PersonModel person);
  Future<void> deletePerson(String id);
  Future<PersonModel> updatePerson(PersonModel person);
}

class PersonFirestoreDataSourceImpl implements PersonFirestoreDataSource {
  final FirebaseFirestore firestore;
  PersonFirestoreDataSourceImpl(this.firestore);
  static const _collection = 'persons';

  @override
  Future<List<PersonModel>> getPersons() async {
    final snapshot = await firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => PersonModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<List<PersonModel>> getPersonsByOwner(String ownerId) async {
    final snapshot = await firestore
        .collection(_collection)
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs
        .map((doc) => PersonModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<PersonModel> addPerson(PersonModel person) async {
    await firestore.collection(_collection).doc(person.id).set(person.toJson());
    return person;
  }

  @override
  Future<void> deletePerson(String id) async {
    await firestore.collection(_collection).doc(id).delete();
  }

  @override
  Future<PersonModel> updatePerson(PersonModel person) async {
    await firestore
        .collection(_collection)
        .doc(person.id)
        .update(person.toJson());
    return person;
  }
}
