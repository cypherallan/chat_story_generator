import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'edit_participant_page.dart';
import '../../../../injection_container.dart' as di;
import '../cubit/person_cubit.dart';
import '../widgets/person_card.dart';
import 'add_participant_page.dart';

class PersonsListPage extends StatelessWidget {
  const PersonsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<PersonCubit>()..loadPersons(),
      child: const _PersonsListView(),
    );
  }
}

class _PersonsListView extends StatelessWidget {
  const _PersonsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        centerTitle: true,
      ),
      body: BlocBuilder<PersonCubit, PersonState>(
        builder: (context, state) {
          if (state is PersonLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is PersonError) {
            return Center(
              child: Text(state.message),
            );
          }

          if (state is PersonLoaded) {
            if (state.persons.isEmpty) {
              return const Center(
                child: Text(
                  'No participants yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView.builder(
              itemCount: state.persons.length,
              itemBuilder: (context, index) {
                final person = state.persons[index];

                return PersonCard(
                  person: person,
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditParticipantPage(
                          person: person,
                        ),
                      ),
                    );
                  },
                  onDelete: () {
                    context.read<PersonCubit>().removePerson(person.id);
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<PersonCubit>(),
                child: const AddParticipantPage(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Participant'),
      ),
    );
  }
}
