import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import '../theme/app_theme.dart';
import '../utils/navigation.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/nav_header.dart';
import '../widgets/search_field.dart';
import 'dialog_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _repo = ContactsRepository.shared;
  final _searchCtrl = TextEditingController();
  List<Contact> _all = [];
  List<Contact> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _repo.fetchContacts();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
      _applyFilter();
    });
  }

  /// Пересобирает список под текущий запрос. Вызывается в setState.
  void _applyFilter() {
    final query = _searchCtrl.text;
    _filtered = _all.where((c) => c.matches(query)).toList();
  }

  /// Открывает диалог. Вернувшись, сбрасывает поиск (без фокуса и клавиатуры)
  /// и перечитывает список — контакт могли переименовать или удалить.
  Future<void> _openDialog(Contact c) async {
    await pushScreen<void>(context, DialogScreen(contact: c));
    if (!mounted) return;
    _searchCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(title: 'Новый чат', onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchField(
                hint: 'Найти пользователя',
                controller: _searchCtrl,
                onChanged: (_) => setState(_applyFilter),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('КОНТАКТЫ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(
                          child: Text('Ничего не найдено',
                              style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 15)),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: 78,
                            color: palette.divider,
                          ),
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return InkWell(
                              onTap: () => _openDialog(c),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Row(
                                  children: [
                                    CustomAvatar(
                                        initials: c.initials,
                                        color: c.color,
                                        size: 46),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: palette.textPrimary)),
                                        Text(c.username,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    palette.textSecondary)),
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
