import 'package:flutter/material.dart';

import 'simulated_status_bar.dart';

class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SimulatedStatusBar(),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
