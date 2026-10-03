import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/chat_list_controller.dart';
import '../theme/app_theme.dart';
import '../utils/navigation.dart';
import '../widgets/chat_tile.dart';
import '../widgets/search_field.dart';
import 'dialog_screen.dart';
import 'new_chat_screen.dart';
import 'profile_screen.dart';

/// Экран «Чаты». Состояние (контакты, превью, поиск) живёт в
/// [ChatListController] и подаётся через Provider.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatListController>(
      create: (_) => ChatListController()..load(),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatefulWidget {
  const _ChatListView();

  @override
  State<_ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<_ChatListView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Открывает экран. Вернувшись, сбрасывает поиск (без фокуса и клавиатуры)
  /// и перечитывает данные — контакт могли переименовать или удалить.
  Future<void> _open(Widget screen) async {
    final controller = context.read<ChatListController>();
    await pushScreen<void>(context, screen);
    if (!mounted) return;
    _searchCtrl.clear();
    controller.setQuery('');
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = context.watch<ChatListController>();
    final chats = state.chats;
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
                              color: palette.textPrimary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () => _open(const NewChatScreen()),
                      ),
                      InkWell(
                        onTap: () => _open(const ProfileScreen()),
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
                  child: SearchField(
                    hint: 'Поиск',
                    controller: _searchCtrl,
                    onChanged: context.read<ChatListController>().setQuery,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : chats.isEmpty
                          ? Center(
                              child: Text('Ничего не найдено',
                                  style: TextStyle(
                                      color: palette.textSecondary)),
                            )
                          : ListView.separated(
                              itemCount: chats.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 0.5,
                                thickness: 0.5,
                                indent: 84,
                                color: palette.divider,
                              ),
                              itemBuilder: (_, i) {
                                final chat = chats[i];
                                return ChatTile(
                                  contact: chat.contact,
                                  lastMessage: chat.lastMessage,
                                  time: chat.time,
                                  unread: chat.unread,
                                  onTap: () => _open(
                                      DialogScreen(contact: chat.contact)),
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
                onPressed: () => _open(const NewChatScreen()),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
