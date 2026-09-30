import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_tile.dart';
import 'dialog_screen.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';

class ChatData {
  final Contact contact;
  final String lastMessage;
  final String time;
  final int unread;
  final int ts;
  const ChatData(
      this.contact, this.lastMessage, this.time, this.unread, this.ts);
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final repo = ContactsRepository();
  final storage = PrefsStorage();
  final _searchCtrl = TextEditingController();
  List<Contact> contacts = [];
  List<Contact> filtered = [];
  Map<String, Map<String, dynamic>> chatInfo = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final data = await repo.fetchContacts();
    final info = await storage.getChatInfo();
    if (!mounted) return;
    setState(() {
      contacts = data;
      filtered = data;
      chatInfo = info;
      loading = false;
    });
  }

  void _onSearch(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => filtered = contacts);
      return;
    }
    setState(() {
      filtered = contacts.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _openDialog(Contact c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DialogScreen(contact: c)),
    );
    if (mounted) await load();
  }

  List<ChatData> _chatsFrom(List<Contact> source) {
    final result = <ChatData>[];
    for (final c in source) {
      final info = chatInfo[c.id];
      final text = (info?['text'] as String?) ?? '';
      final time = (info?['time'] as String?) ?? '';
      final ts = (info?['ts'] as int?) ?? 0;
      result.add(ChatData(
        c,
        text.isEmpty ? 'Начните диалог' : text,
        time,
        0,
        ts,
      ));
    }
    result.sort((a, b) {
      if (a.ts != b.ts) return b.ts.compareTo(a.ts);
      return a.contact.name
          .toLowerCase()
          .compareTo(b.contact.name.toLowerCase());
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final chats = _chatsFrom(filtered);
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
                      Text('Чаты',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NewChatScreen()),
                          );
                          if (mounted) await load();
                        },
                      ),
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                          if (mounted) await load();
                        },
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bubbleIn,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search,
                            size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearch,
                            style:
                                TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Поиск',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : chats.isEmpty
                          ? Center(
                              child: Text('Ничего не найдено',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            )
                          : ListView.separated(
                              itemCount: chats.length,
                              separatorBuilder: (_, _) => Divider(
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
                                  onTap: () => _openDialog(chat.contact),
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NewChatScreen()),
                  );
                  if (mounted) await load();
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
