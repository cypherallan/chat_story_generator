import 'package:flutter/material.dart';

import '../../../project_management/domain/entities/project.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../message_management/presentation/pages/add_message_page.dart';

import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../../../message_management/presentation/widgets/conversation_header.dart';

class ConversationPage extends StatelessWidget {
  final Project project;

  const ConversationPage({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: BlocBuilder<PersonCubit, PersonState>(
          builder: (context, state) {
            if (state is PersonLoaded) {
              final otherPersonId = project.participantIds.length > 1
                  ? project.participantIds[1]
                  : project.participantIds[0];

              final otherPerson = state.persons.firstWhere(
                (person) => person.id == otherPersonId,
              );

              return ConversationHeader(
                person: otherPerson,
              );
            }

            return const Text(
              'Conversation',
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<PersonCubit, PersonState>(
                builder: (context, personState) {
                  if (personState is! PersonLoaded) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return BlocBuilder<MessageCubit, MessageState>(
                    builder: (context, messageState) {
                      if (messageState is MessageLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (messageState is MessageError) {
                        return Center(
                          child: Text(messageState.message),
                        );
                      }

                      if (messageState is MessageLoaded) {
                        if (messageState.messages.isEmpty) {
                          return const Center(
                            child: Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: messageState.messages.length,
                          itemBuilder: (context, index) {
                            final message = messageState.messages[index];

                            final matchingPersons = personState.persons
                                .where(
                                    (person) => person.id == message.senderId)
                                .toList();

                            if (matchingPersons.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final sender = matchingPersons.first;

                            final isMine =
                                sender.id == project.participantIds.first;

                            return MessageBubble(
                              message: message,
                              sender: sender,
                              isMine: isMine,
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<MessageCubit>(),
                  ),
                  BlocProvider.value(
                    value: context.read<PersonCubit>(),
                  ),
                ],
                child: AddMessagePage(
                  projectId: project.id,
                  participantIds: project.participantIds,
                ),
              ),
            ),
          );

          if (created == true) {
            context.read<MessageCubit>().loadMessages(project.id);
          }
        },
        icon: const Icon(Icons.add_comment),
        label: const Text('Add Message'),
      ),
    );
  }
}
