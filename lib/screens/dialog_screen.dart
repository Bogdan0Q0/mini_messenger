import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/contact.dart';
import '../data/models/message.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/message_bubble.dart';

class DialogScreen extends StatefulWidget {
  final Contact contact;
  const DialogScreen({super.key, required this.contact});

  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  final messages = <Message>[];
  final input = TextEditingController();
  final storage = PrefsStorage();
  bool loaded = false;
  bool contactTyping = false;
  String currentName = '';

  static const autoReplies = [
    'Привет!',
    'Хорошо, договорились',
    'Я подумаю',
    'Скоро отвечу подробнее',
    'Ок',
    'Спасибо!',
    'Да, конечно',
    'Не уверен',
    'Позже напишу',
    'Отлично!',
    'Согласен полностью',
    'Интересно',
  ];

  @override
  void initState() {
    super.initState();
    currentName = widget.contact.name;
    loadMessages();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  String now() {
    final n = DateTime.now();
    return '${n.hour}:${n.minute.toString().padLeft(2, '0')}';
  }

  String previewOf(Message m) {
    if (m.imagePath != null && m.imagePath!.isNotEmpty && m.text.isEmpty) {
      return 'Фото';
    }
    return m.text;
  }

  Future<void> touch() async {
    if (messages.isEmpty) {
      await storage.markChatOpened(widget.contact.id);
      return;
    }
    final last = messages.last;
    await storage.updateChatPreview(
      widget.contact.id,
      previewOf(last),
      last.time,
    );
  }

  Future<void> loadMessages() async {
    final saved = await storage.loadMessages(widget.contact.id);
    if (saved.isNotEmpty) {
      messages.addAll(saved);
    } else {
      messages.addAll([
        const Message(
            id: 1, text: 'Привет, как дела', time: '14:30', outgoing: false),
        const Message(
            id: 2,
            text: 'Привет, все отлично, а у тебя',
            time: '14:31',
            outgoing: true),
        const Message(id: 3, text: 'Тоже хорошо', time: '14:31', outgoing: false),
        const Message(
            id: 4, text: 'Что делаешь сегодня', time: '14:32', outgoing: true),
      ]);
    }
    if (mounted) setState(() => loaded = true);
    await touch();
  }

  Future<void> persist() async {
    await storage.saveMessages(widget.contact.id, messages);
  }

  void snack(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> sendText() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      snack('Сообщение слишком длинное', true);
      return;
    }
    setState(() {
      messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch,
        text: text,
        time: now(),
        outgoing: true,
      ));
      input.clear();
    });
    await persist();
    await storage.updateChatPreview(widget.contact.id, text, messages.last.time);
    scheduleReply();
  }

  Future<void> sendPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch,
          text: '',
          time: now(),
          outgoing: true,
          imagePath: picked.path,
        ));
      });
      await persist();
      await storage.updateChatPreview(
          widget.contact.id, 'Фото', messages.last.time);
      scheduleReply();
    } catch (e) {
      snack('Не удалось выбрать фото', true);
    }
  }

  Future<void> scheduleReply() async {
    setState(() => contactTyping = true);
    final ms = 800 + (DateTime.now().microsecond % 1200);
    await Future.delayed(Duration(milliseconds: ms));
    if (!mounted) return;
    final reply = autoReplies[DateTime.now().millisecond % autoReplies.length];
    setState(() {
      contactTyping = false;
      messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch,
        text: reply,
        time: now(),
        outgoing: false,
      ));
    });
    await persist();
    await storage.updateChatPreview(
        widget.contact.id, reply, messages.last.time);
  }

  Future<void> showMenu() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.primary),
              title: Text('Переименовать',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                renameContact();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Удалить',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                confirmDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> renameContact() async {
    final ctrl = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Переименовать',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Новое имя'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text('Сохранить',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await storage.setNameOverride(widget.contact.id, result);
    if (!mounted) return;
    setState(() => currentName = result);
    snack('Контакт переименован', false);
  }

  Future<void> confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Удалить чат?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Контакт и вся переписка будут удалены.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await storage.saveMessages(widget.contact.id, []);
    await storage.addDeletedId(widget.contact.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    bottom: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.primary, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CustomAvatar(
                    initials: _initialsFor(currentName),
                    color: widget.contact.color,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentName,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(
                          contactTyping ? 'печатает...' : 'В сети',
                          style: TextStyle(
                              fontSize: 12,
                              color: contactTyping
                                  ? AppColors.primary
                                  : AppColors.success),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        color: AppColors.textSecondary),
                    onPressed: showMenu,
                  ),
                ],
              ),
            ),
            Expanded(
              child: !loaded
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: messages.length + (contactTyping ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (contactTyping && i == messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.bubbleIn,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text('...',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15)),
                            ),
                          );
                        }
                        final m = messages[i];
                        return MessageBubble(
                          text: m.text,
                          time: m.time,
                          outgoing: m.outgoing,
                          imagePath: m.imagePath,
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file,
                        color: AppColors.textSecondary),
                    onPressed: sendPhoto,
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.bubbleIn,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: input,
                        onSubmitted: (_) => sendText(),
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Сообщение...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          hintStyle:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: sendText,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialsFor(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    final buf = StringBuffer();
    for (var i = 0; i < parts.length && i < 2; i++) {
      if (parts[i].isNotEmpty) buf.write(parts[i][0]);
    }
    final s = buf.toString().toUpperCase();
    return s.isEmpty ? 'U' : s;
  }
}
