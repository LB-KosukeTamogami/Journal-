import 'package:flutter/material.dart';

class AcornIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AcornIcon({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).primaryColor;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AcornPainter(color: iconColor),
      ),
    );
  }
}

class AcornPainter extends CustomPainter {
  final Color color;

  AcornPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final capPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // どんぐりの帽子部分（上部）
    final capPath = Path();
    capPath.moveTo(size.width * 0.5, size.height * 0.1);
    capPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.2,
      size.width * 0.2, size.height * 0.35,
    );
    capPath.lineTo(size.width * 0.8, size.height * 0.35);
    capPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.2,
      size.width * 0.5, size.height * 0.1,
    );
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // どんぐりの本体部分（下部）
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.2, size.height * 0.35);
    bodyPath.quadraticBezierTo(
      size.width * 0.2, size.height * 0.7,
      size.width * 0.5, size.height * 0.9,
    );
    bodyPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.7,
      size.width * 0.8, size.height * 0.35,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, paint);

    // 帽子の模様（横線）
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;

    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.25),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}