import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool outgoing;

  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    required this.outgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: outgoing ? AppColors.primary : AppColors.bubbleIn,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(outgoing ? 18 : 4),
            bottomRight: Radius.circular(outgoing ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: outgoing ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: outgoing ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
