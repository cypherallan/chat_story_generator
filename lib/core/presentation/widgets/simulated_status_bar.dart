import 'dart:async';

import 'package:flutter/material.dart';

class SimulatedStatusBar extends StatefulWidget {
  const SimulatedStatusBar({
    super.key,
  });

  @override
  State<SimulatedStatusBar> createState() => _SimulatedStatusBarState();
}

class _SimulatedStatusBarState extends State<SimulatedStatusBar> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _currentTime = DateTime.now();

    // Update every second so the clock is always accurate.
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _currentTime = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final hour = _currentTime.hour % 12 == 0 ? 12 : _currentTime.hour % 12;

    final minute = _currentTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        child: Row(
          children: [
            Text(_formatTime()),

            const Spacer(),

            // Fake mobile signal
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 3,
                  height: 5,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Container(
                  width: 3,
                  height: 8,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Container(
                  width: 3,
                  height: 11,
                  color: Colors.white,
                ),
                const SizedBox(width: 2),
                Container(
                  width: 3,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),

            const SizedBox(width: 7),

            const Text(
              '5G',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 7),

            // Fake Wi-Fi
            const Icon(
              Icons.wifi,
              size: 16,
              color: Colors.white,
            ),

            const SizedBox(width: 7),

            const Text('87%'),

            const SizedBox(width: 3),

            // Fake battery
            Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 2),

            Container(
              width: 2,
              height: 5,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
