import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../theme/app_theme.dart';
import 'custom_avatar.dart';

class ChatTile extends StatelessWidget {
  final Contact contact;
  final String lastMessage;
  final String time;
  final int unread;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.contact,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: hasUnread ? const Color(0xFFE0F2FE) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CustomAvatar(initials: contact.initials, color: contact.color, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ),
                      if (hasUnread) const SizedBox(width: 8),
                      if (hasUnread)
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
