import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';

class ConversationTypingSection extends StatelessWidget {
  final bool otherPersonTyping;

  const ConversationTypingSection({
    super.key,
    required this.otherPersonTyping,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, state) {
        if (state is! PersonLoaded) return const SizedBox.shrink();
        return TypingIndicator(visible: otherPersonTyping);
      },
    );
  }
}
