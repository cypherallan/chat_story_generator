import 'dart:async';

import 'package:flutter/material.dart';

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({
    super.key,
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> {
  bool _visible = true;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: 550),
      (_) {
        if (!mounted) return;

        setState(() {
          _visible = !_visible;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _visible ? 1.0 : 0.0,
      child: Container(
        width: 2,
        height: 20,
        margin: const EdgeInsets.only(
          left: 1,
        ),
        color: const Color(0xFF474747),
      ),
    );
  }
}
