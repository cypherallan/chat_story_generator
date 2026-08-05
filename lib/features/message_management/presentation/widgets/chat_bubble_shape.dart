import 'package:flutter/material.dart';

class ChatBubbleShape extends StatelessWidget {
  final Widget child;
  final bool isMine;
  final bool isSelected;

  const ChatBubbleShape({
    super.key,
    required this.child,
    required this.isMine,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        isMine: isMine,
        color: isSelected
            ? const Color(0x3325D366)
            : isMine
                ? const Color(0xffE7FFDB)
                : Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMine ? 10 : 16,
          8,
          isMine ? 16 : 10,
          8,
        ),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final bool isMine;
  final Color color;

  _BubblePainter({
    required this.isMine,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    const radius = 16.0;
    const tail = 8.0;

    if (!isMine) {
      path.moveTo(tail, radius);

      path.quadraticBezierTo(
        tail,
        0,
        tail + radius,
        0,
      );

      path.lineTo(size.width - radius, 0);

      path.quadraticBezierTo(
        size.width,
        0,
        size.width,
        radius,
      );

      path.lineTo(size.width, size.height - radius);

      path.quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      );

      path.lineTo(radius, size.height);

      path.quadraticBezierTo(
        0,
        size.height,
        0,
        size.height - radius,
      );

      path.lineTo(0, 18);

      path.quadraticBezierTo(
        0,
        15,
        5,
        13,
      );

      path.quadraticBezierTo(
        8,
        12,
        tail,
        14,
      );

      path.lineTo(tail, radius);
    } else {
      path.moveTo(radius, 0);

      path.lineTo(size.width - radius - tail, 0);

      path.quadraticBezierTo(
        size.width - tail,
        0,
        size.width - tail,
        radius,
      );

      path.lineTo(size.width - tail, 14);

      path.quadraticBezierTo(
        size.width,
        15,
        size.width,
        18,
      );

      path.quadraticBezierTo(
        size.width,
        21,
        size.width - tail,
        22,
      );

      path.lineTo(size.width - tail, size.height - radius);

      path.quadraticBezierTo(
        size.width - tail,
        size.height,
        size.width - radius - tail,
        size.height,
      );

      path.lineTo(radius, size.height);

      path.quadraticBezierTo(
        0,
        size.height,
        0,
        size.height - radius,
      );

      path.lineTo(0, radius);

      path.quadraticBezierTo(
        0,
        0,
        radius,
        0,
      );
    }

    canvas.drawShadow(path, Colors.black26, 2, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isMine != isMine;
  }
}
