import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/contact.dart';
import '../data/models/message.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/storage/media_storage.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../utils/navigation.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/message_bubble.dart';
import 'contact_profile_screen.dart';
import 'photo_viewer_screen.dart';

class DialogScreen extends StatefulWidget {
  final Contact contact;
  const DialogScreen({super.key, required this.contact});

  @override
  State<DialogScreen> createState() => _DialogScreenState();
}

class _DialogScreenState extends State<DialogScreen> {
  final messages = <Message>[];
  final input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final storage = PrefsStorage();
  final _contacts = ContactsRepository.shared;
  final _media = MediaStorage();
  final _random = Random();
  late Contact _contact = widget.contact;
  bool loaded = false;

  /// Сколько ответов собеседника «печатается» сейчас. Счётчик, а не флаг,
  /// чтобы индикатор не гас, пока ждёт ответа хотя бы одно сообщение.
  int _typingCount = 0;
  bool get contactTyping => _typingCount > 0;

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
    _focus.addListener(_onFocusChange);
    loadMessages();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _scroll.dispose();
    input.dispose();
    super.dispose();
  }

  /// Когда открывается клавиатура, список сжимается — прокручиваем к
  /// последнему сообщению, чтобы оно не оказалось под клавиатурой.
  void _onFocusChange() {
    if (_focus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), _scrollToEnd);
    }
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(end,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  String now() {
    final n = DateTime.now();
    return '${n.hour}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> loadMessages() async {
    final saved = await storage.loadMessages(_contact.id);
    messages.addAll(saved);
    if (!mounted) return;
    setState(() => loaded = true);
    _scrollToEnd(animate: false);
    // Открытый чат поднимается в списке наверх.
    await storage.markChatOpened(_contact.id);
  }

  void snack(String msg, bool error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  /// Добавляет сообщение в чат, сохраняет переписку и обновляет превью.
  Future<void> _addMessage(Message message, {required String preview}) async {
    setState(() => messages.add(message));
    _scrollToEnd();
    await storage.saveMessages(_contact.id, messages);
    await storage.updateChatPreview(_contact.id, preview, message.time);
  }

  Future<void> sendText() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      snack('Сообщение слишком длинное', true);
      return;
    }
    input.clear();
    await _addMessage(
      Message(
        id: DateTime.now().microsecondsSinceEpoch,
        text: text,
        time: now(),
        outgoing: true,
      ),
      preview: text,
    );
    scheduleReply();
  }

  Future<void> sendPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;
      final userId = await storage.getCurrentUserId();
      if (userId == null) return;
      // Копия в папке приложения: временный файл image_picker могут стереть.
      final savedPath = await _media.importImage(
        picked.path,
        userId: userId,
        folder: MediaStorage.chatFolder(_contact.id),
      );
      if (!mounted) return;
      await _addMessage(
        Message(
          id: DateTime.now().microsecondsSinceEpoch,
          text: '',
          time: now(),
          outgoing: true,
          imagePath: savedPath,
        ),
        preview: 'Фото',
      );
      scheduleReply();
    } catch (e) {
      if (mounted) snack('Не удалось отправить фото', true);
    }
  }

  Future<void> scheduleReply() async {
    setState(() => _typingCount++);
    _scrollToEnd();
    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(1200)));
    if (!mounted) return;
    setState(() => _typingCount--);
    final reply = autoReplies[_random.nextInt(autoReplies.length)];
    await _addMessage(
      Message(
        id: DateTime.now().microsecondsSinceEpoch,
        text: reply,
        time: now(),
        outgoing: false,
      ),
      preview: reply,
    );
  }

  /// Открывает фото из чата на весь экран, с листанием по всем фото чата.
  void _openPhoto(Message message) {
    final photos = [
      for (final m in messages)
        if (m.imagePath != null && m.imagePath!.isNotEmpty) m.imagePath!,
    ];
    final index = photos.indexOf(message.imagePath!);
    pushScreen<void>(
      context,
      PhotoViewerScreen(paths: photos, initialIndex: index < 0 ? 0 : index),
    );
  }

  /// Профиль контакта: переименование, удаление, фото. Если контакт там
  /// удалили, чат закрывается; если переименовали — обновляется имя.
  Future<void> _openProfile() async {
    await pushScreen<void>(context, ContactProfileScreen(contact: _contact));
    if (!mounted) return;
    final updated = await _contacts.findById(_contact.id);
    if (!mounted) return;
    if (updated == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _contact = updated);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                border:
                    Border(bottom: BorderSide(color: palette.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.primary, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _openProfile,
                      child: Row(
                        children: [
                          CustomAvatar(
                            initials: _contact.initials,
                            color: _contact.color,
                            size: 38,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_contact.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary)),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMessages(palette)),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: palette.surface,
                border:
                    Border(top: BorderSide(color: palette.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: palette.textSecondary),
                    onPressed: sendPhoto,
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.bubbleIn,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: input,
                        focusNode: _focus,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        // После отправки фокус остаётся в поле, чтобы можно
                        // было сразу писать дальше.
                        onSubmitted: (_) {
                          sendText();
                          _focus.requestFocus();
                        },
                        style: TextStyle(color: palette.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Сообщение...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          hintStyle: TextStyle(color: palette.textSecondary),
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
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 18),
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

  Widget _buildMessages(AppPalette palette) {
    if (!loaded) return const Center(child: CircularProgressIndicator());
    if (messages.isEmpty && !contactTyping) {
      return Center(
        child: Text('Напишите первое сообщение',
            style: TextStyle(color: palette.textSecondary, fontSize: 15)),
      );
    }
    // Нажатие на пустое место списка убирает клавиатуру.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: messages.length + (contactTyping ? 1 : 0),
        itemBuilder: (_, i) {
          if (contactTyping && i == messages.length) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: palette.bubbleIn,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('...',
                    style:
                        TextStyle(color: palette.textSecondary, fontSize: 15)),
              ),
            );
          }
          final m = messages[i];
          final hasImage = m.imagePath != null && m.imagePath!.isNotEmpty;
          return MessageBubble(
            text: m.text,
            time: m.time,
            outgoing: m.outgoing,
            imagePath: m.imagePath,
            onImageTap: hasImage ? () => _openPhoto(m) : null,
          );
        },
      ),
    );
  }
}
