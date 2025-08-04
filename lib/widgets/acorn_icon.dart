import 'package:flutter/material.dart';

class AcornIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AcornIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.eco,  // Using eco icon as a placeholder for acorn
      size: size,
      color: color ?? Theme.of(context).primaryColor,
    );
  }
}