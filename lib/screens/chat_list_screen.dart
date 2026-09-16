import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_tile.dart';
import '../widgets/search_field.dart';
import 'dialog_screen.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';

class ChatData {
  final Contact contact;
  final String lastMessage;
  final String time;
  final int unread;
  const ChatData(this.contact, this.lastMessage, this.time, this.unread);
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final repo = ContactsRepository();
  List<Contact> contacts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await repo.fetchContacts();
    if (!mounted) return;
    setState(() {
      contacts = data;
      loading = false;
    });
  }

  List<ChatData> get chats {
    final messages = [
      'Привет, как дела',
      'До завтра',
      'Хорошо, договорились',
      'Посмотри файл, который я отправил',
      'Спасибо',
      'Ок',
      'Созвонимся позже',
      'Отправил на почту',
      'Спасибо большое',
      'Договорились',
    ];
    final times = [
      '14:32', '13:15', '12:47', '11:20', 'Вчера',
      'Вчера', 'Пн', 'Пн', 'Вс', 'Вс',
    ];
    final result = <ChatData>[];
    for (var i = 0; i < contacts.length; i++) {
      result.add(ChatData(
        contacts[i],
        messages[i % messages.length],
        times[i % times.length],
        i == 0 ? 2 : 0,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 30, left: 20, right: 20, bottom: 12),
                  child: Row(
                    children: [
                      const Text('Чаты',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NewChatScreen(contacts: contacts)),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SearchField(hint: 'Поиск'),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          itemCount: chats.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: 84,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (_, i) {
                            final chat = chats[i];
                            return ChatTile(
                              contact: chat.contact,
                              lastMessage: chat.lastMessage,
                              time: chat.time,
                              unread: chat.unread,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DialogScreen(contact: chat.contact)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NewChatScreen(contacts: contacts)),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
