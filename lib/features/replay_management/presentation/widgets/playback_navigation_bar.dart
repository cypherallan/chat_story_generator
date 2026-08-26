/*import 'package:flutter/material.dart';

class PlaybackNavigationBar extends StatelessWidget {
  final VoidCallback onBackPressed;

  const PlaybackNavigationBar({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 48,
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavigationButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBackPressed,
            ),
            const _NavigationButton(
              icon: Icons.circle_outlined,
            ),
            const _NavigationButton(
              icon: Icons.crop_square_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavigationButton({
    required this.icon,
    this.onTap,
  });

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _pressed = false;

  void _handleTap() async {
    setState(() => _pressed = true);

    await Future.delayed(const Duration(milliseconds: 120));

    if (mounted) {
      setState(() => _pressed = false);
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 70,
        height: 36,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.grey.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
*/
