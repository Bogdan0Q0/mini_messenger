import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
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
        const Message(
            id: 3, text: 'Тоже хорошо', time: '14:31', outgoing: false),
        const Message(
            id: 4,
            text: 'Что делаешь сегодня',
            time: '14:32',
            outgoing: true),
      ]);
    }
    if (mounted) setState(() => loaded = true);
  }

  void send() {
    final text = input.text.trim();
    if (text.isEmpty) return;
    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сообщение слишком длинное'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final now = DateTime.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch,
        text: text,
        time: time,
        outgoing: true,
      ));
      input.clear();
    });
    storage.saveMessages(widget.contact.id, messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
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
                    initials: widget.contact.initials,
                    color: widget.contact.color,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.contact.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const Text('В сети',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary),
                    onPressed: () {},
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
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        return MessageBubble(
                          text: m.text,
                          time: m.time,
                          outgoing: m.outgoing,
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: AppColors.textSecondary),
                    onPressed: () {},
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
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(
                          hintText: 'Сообщение...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          hintStyle:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: send,
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
}
