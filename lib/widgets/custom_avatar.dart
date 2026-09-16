import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const CustomAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
        ),
      ),
    );
  }
}
