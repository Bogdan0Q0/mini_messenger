import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool outgoing;
  final String? imagePath;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.outgoing,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final hasText = text.isNotEmpty;

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: const BoxConstraints(maxWidth: 270),
        padding: EdgeInsets.all(hasImage && !hasText ? 4 : 0),
        decoration: BoxDecoration(
          color: hasImage && !hasText
              ? Colors.transparent
              : (outgoing ? AppColors.primary : AppColors.bubbleIn),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(outgoing ? 18 : 4),
            bottomRight: Radius.circular(outgoing ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              Padding(
                padding: EdgeInsets.all(hasText ? 6 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(imagePath!),
                    width: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 240,
                      height: 160,
                      color: AppColors.divider,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 9, 14, 0),
                child: Text(
                  text,
                  style: TextStyle(
                    color: outgoing ? Colors.white : AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 3, 14, hasText ? 9 : 6),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: hasImage && !hasText
                      ? Colors.white
                      : (outgoing ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
