import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_model.dart';

abstract class PersonLocalDataSource {
  Future<List<PersonModel>> getPersons();
  Future<PersonModel> addPerson(PersonModel person);
  Future<void> deletePerson(String id);
}

const String _cachedPersonsKey = 'CACHED_PERSONS';

class PersonLocalDataSourceImpl implements PersonLocalDataSource {
  final SharedPreferences prefs;

  PersonLocalDataSourceImpl(this.prefs);

  @override
  Future<List<PersonModel>> getPersons() async {
    final jsonString = prefs.getString(_cachedPersonsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((jsonItem) => PersonModel.fromJson(jsonItem)).toList();
  }

  @override
  Future<PersonModel> addPerson(PersonModel person) async {
    final persons = await getPersons();
    persons.add(person);
    await _cachePersons(persons);
    return person;
  }

  @override
  Future<void> deletePerson(String id) async {
    final persons = await getPersons();
    persons.removeWhere((p) => p.id == id);
    await _cachePersons(persons);
  }

  Future<void> _cachePersons(List<PersonModel> persons) async {
    final jsonList = persons.map((p) => p.toJson()).toList();
    await prefs.setString(_cachedPersonsKey, json.encode(jsonList));
  }
}
