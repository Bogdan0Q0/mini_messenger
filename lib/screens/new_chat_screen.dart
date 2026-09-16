import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/nav_header.dart';
import '../widgets/search_field.dart';
import 'dialog_screen.dart';

class NewChatScreen extends StatelessWidget {
  final List<Contact> contacts;
  const NewChatScreen({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(title: 'Новый чат', onBack: () => Navigator.pop(context)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SearchField(hint: 'Найти пользователя'),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('КОНТАКТЫ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 78,
                  color: AppColors.divider,
                ),
                itemBuilder: (_, i) {
                  final c = contacts[i];
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DialogScreen(contact: c)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          CustomAvatar(
                              initials: c.initials, color: c.color, size: 46),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              Text(c.username,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
