import 'dart:io';
import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  final String? imagePath;

  const CustomAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 48,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsWidget(),
          ),
        );
      }
    }
    return _initialsWidget();
  }

  Widget _initialsWidget() {
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
