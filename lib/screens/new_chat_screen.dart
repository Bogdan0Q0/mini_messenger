import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/nav_header.dart';
import 'dialog_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _repo = ContactsRepository();
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
      _filtered = data;
      _loading = false;
    });
  }

  void _onSearch(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    setState(() {
      _filtered = _all.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _openDialog(Contact c) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DialogScreen(contact: c)),
    );
    if (result == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            NavHeader(title: 'Новый чат', onBack: () => Navigator.pop(context)),
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
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Найти пользователя',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      ),
                  ],
                ),
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
                        color: AppColors.textSecondary,
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
                                  color: AppColors.textSecondary,
                                  fontSize: 15)),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: 78,
                            color: AppColors.divider,
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
                                                color:
                                                    AppColors.textPrimary)),
                                        Text(c.username,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors
                                                    .textSecondary)),
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
