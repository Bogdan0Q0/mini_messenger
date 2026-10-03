import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../storage/contacts_file_storage.dart';
import '../storage/media_storage.dart';
import '../storage/prefs_storage.dart';

/// Источник списка контактов текущего пользователя.
///
/// Единственный источник правды — файл `contacts_<id>.json` в папке
/// приложения. При первом входе пользователя он создаётся из REST API
/// (или из встроенного списка, если сеть недоступна). Дальше любое
/// переименование или удаление сразу записывается в этот файл.
class ContactsRepository {
  ContactsRepository({
    ContactsFileStorage? fileStorage,
    MediaStorage? mediaStorage,
    PrefsStorage? prefs,
    Future<List<Contact>?> Function()? remoteSource,
  })  : _file = fileStorage ?? ContactsFileStorage(),
        _media = mediaStorage ?? MediaStorage(),
        _prefs = prefs ?? PrefsStorage(),
        _remoteSource = remoteSource ?? _fetchFromApi;

  /// Общий экземпляр для всех экранов: список читается с диска один раз
  /// и дальше отдаётся из памяти. При смене пользователя кэш сбрасывается.
  static final ContactsRepository shared = ContactsRepository();

  static const _usersUrl = 'https://jsonplaceholder.typicode.com/users';

  final ContactsFileStorage _file;
  final MediaStorage _media;
  final PrefsStorage _prefs;
  final Future<List<Contact>?> Function() _remoteSource;

  String? _cacheUserId;
  List<Contact>? _cache;
  Future<List<Contact>>? _loading;

  Future<List<Contact>> fetchContacts() async {
    final userId = await _prefs.getCurrentUserId();
    if (userId == null) return [];
    return List.of(await _ensureLoaded(userId));
  }

  /// Контакт по id или null, если его удалили.
  Future<Contact?> findById(String id) async {
    final contacts = await fetchContacts();
    for (final c in contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Переименовывает контакт и сразу сохраняет изменение в contacts_<id>.json.
  Future<void> rename(String id, String newName) async {
    final name = newName.trim();
    final userId = await _prefs.getCurrentUserId();
    if (name.isEmpty || userId == null) return;
    final contacts = await _ensureLoaded(userId);
    final index = contacts.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final updated = List.of(contacts)..[index] = contacts[index].withName(name);
    await _file.write(userId, updated);
    _store(userId, updated);
  }

  /// Удаляет контакт из файла вместе с перепиской и фотографиями.
  Future<void> delete(String id) async {
    final userId = await _prefs.getCurrentUserId();
    if (userId == null) return;
    final contacts = await _ensureLoaded(userId);
    final updated = contacts.where((c) => c.id != id).toList();
    if (updated.length != contacts.length) {
      await _file.write(userId, updated);
      _store(userId, updated);
    }
    await _prefs.deleteChatData(id);
    try {
      await _media.deleteFolder(userId, MediaStorage.chatFolder(id));
    } catch (e) {
      debugPrint('Не удалось удалить фото чата $id ($e)');
    }
  }

  void _store(String userId, List<Contact> contacts) {
    if (_cacheUserId == userId) _cache = contacts;
  }

  Future<List<Contact>> _ensureLoaded(String userId) {
    if (_cacheUserId != userId) {
      _cacheUserId = userId;
      _cache = null;
      _loading = null;
    }
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    final pending = _loading;
    if (pending != null) return pending;
    final future = _load(userId);
    _loading = future;
    return future.whenComplete(() {
      if (identical(_loading, future)) _loading = null;
    });
  }

  Future<List<Contact>> _load(String userId) async {
    var contacts = await _file.read(userId);
    if (contacts == null) {
      contacts = await _seed(userId);
      try {
        await _file.write(userId, contacts);
        await _prefs.clearLegacyContactEdits(userId);
      } catch (e) {
        // Список всё равно работает из памяти; запись повторится при правке.
        debugPrint('contacts_$userId.json: не удалось создать ($e)');
      }
    }
    _store(userId, contacts);
    return contacts;
  }

  /// Начальный список: API или встроенные контакты. Правки из старых версий
  /// (удалённые id и переименования в SharedPreferences) переносятся сюда.
  Future<List<Contact>> _seed(String userId) async {
    final base = await _remoteSource() ?? kFallbackContacts;
    final legacy = await _prefs.getLegacyContactEdits(userId);
    final result = <Contact>[];
    for (final c in base) {
      if (legacy.deletedIds.contains(c.id)) continue;
      final renamed = legacy.nameOverrides[c.id];
      result.add(renamed == null || renamed.isEmpty ? c : c.withName(renamed));
    }
    return result;
  }

  static Future<List<Contact>?> _fetchFromApi() async {
    try {
      final res = await http
          .get(Uri.parse(_usersUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as List;
      return data
          .take(10)
          .whereType<Map<String, dynamic>>()
          .map(Contact.fromApi)
          .toList();
    } catch (_) {
      return null;
    }
  }
}
