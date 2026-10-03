import 'package:flutter/foundation.dart';
import '../data/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/storage/prefs_storage.dart';

/// Строка списка чатов: контакт и данные последнего сообщения.
class ChatData {
  final Contact contact;
  final String lastMessage;
  final String time;
  final int unread;
  final int ts;
  const ChatData(
      this.contact, this.lastMessage, this.time, this.unread, this.ts);
}

/// Состояние экрана «Чаты» (Provider): контакты, превью сообщений, поиск.
/// Экран только отображает [chats] и передаёт сюда запрос поиска.
class ChatListController extends ChangeNotifier {
  ChatListController({ContactsRepository? repo, PrefsStorage? storage})
      : _repo = repo ?? ContactsRepository.shared,
        _storage = storage ?? PrefsStorage();

  final ContactsRepository _repo;
  final PrefsStorage _storage;

  List<Contact> _contacts = const [];
  Map<String, Map<String, dynamic>> _chatInfo = const {};
  List<ChatData> _chats = const [];
  String _query = '';
  bool _loading = true;
  bool _disposed = false;

  bool get loading => _loading;
  List<ChatData> get chats => _chats;

  /// Перечитывает контакты и превью сообщений (например, после возврата
  /// с другого экрана: контакт могли переименовать или удалить).
  Future<void> load() async {
    final contacts = await _repo.fetchContacts();
    final info = await _storage.getChatInfo();
    if (_disposed) return;
    _contacts = contacts;
    _chatInfo = info;
    _loading = false;
    _rebuild();
  }

  void setQuery(String query) {
    if (_query == query) return;
    _query = query;
    _rebuild();
  }

  void _rebuild() {
    _chats = _chatsFrom(_contacts.where((c) => c.matches(_query)));
    notifyListeners();
  }

  List<ChatData> _chatsFrom(Iterable<Contact> source) {
    final result = <ChatData>[];
    for (final c in source) {
      final info = _chatInfo[c.id];
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
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
