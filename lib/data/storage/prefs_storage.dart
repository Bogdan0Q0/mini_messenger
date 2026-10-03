import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/user_account.dart';

/// Обёртка над SharedPreferences.
///
/// Общие настройки (вход, тема, список аккаунтов) хранятся как есть, а всё,
/// что принадлежит конкретному человеку (аватар, переписка, превью чатов),
/// — под ключом `u_<id пользователя>_<имя>`. Поэтому новый пользователь
/// не видит данных предыдущего.
class PrefsStorage {
  static const _kLoggedIn = 'logged_in';
  static const _kRegisteredUsers = 'registered_users';
  static const _kCurrentUser = 'current_user';
  static const _kThemeMode = 'theme_mode';
  static const _kScopedMigrated = 'scoped_data_v1';

  // Ключи данных пользователя (см. _scoped).
  static const _kAvatarPath = 'avatar_path';
  static const _kChatInfo = 'chat_info';
  static const _kMessagesPrefix = 'messages_';
  static const _kDeletedIds = 'deleted_ids';
  static const _kNameOverrides = 'name_overrides';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static String _scoped(String userId, String key) => 'u_${userId}_$key';

  // ---------- Сессия ----------

  Future<bool> isLoggedIn() async {
    final p = await _prefs;
    return p.getBool(_kLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final p = await _prefs;
    await p.setBool(_kLoggedIn, value);
  }

  /// Выход: сессия закрывается, текущий пользователь забывается.
  Future<void> logout() async {
    final p = await _prefs;
    await p.setBool(_kLoggedIn, false);
    await p.remove(_kCurrentUser);
  }

  Future<void> setCurrentUser(UserAccount user) async {
    final p = await _prefs;
    await p.setString(_kCurrentUser, jsonEncode(user.toJson()));
  }

  Future<UserAccount?> getCurrentUser() async => _readCurrentUser(await _prefs);

  Future<String?> getCurrentUserId() async =>
      _readCurrentUser(await _prefs)?.id;

  UserAccount? _readCurrentUser(SharedPreferences p) {
    final raw = p.getString(_kCurrentUser);
    if (raw == null) return null;
    try {
      return UserAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Ключ для данных текущего пользователя или null, если никто не вошёл.
  String? _userKey(SharedPreferences p, String key) {
    final id = _readCurrentUser(p)?.id;
    return id == null ? null : _scoped(id, key);
  }

  // ---------- Аккаунты ----------

  List<UserAccount> _readUsers(SharedPreferences p) {
    final raw = p.getStringList(_kRegisteredUsers) ?? const <String>[];
    final users = <UserAccount>[];
    for (final s in raw) {
      try {
        users.add(UserAccount.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // повреждённую запись пропускаем
      }
    }
    return users;
  }

  Future<void> _writeUsers(SharedPreferences p, List<UserAccount> users) {
    return p.setStringList(
      _kRegisteredUsers,
      users.map((u) => jsonEncode(u.toJson())).toList(),
    );
  }

  static String _normUsername(String s) => s.toLowerCase().replaceAll('@', '');

  bool _isTaken(List<UserAccount> users, String email, String username,
      {String? exceptId}) {
    for (final u in users) {
      if (u.id == exceptId) continue;
      if (email.isNotEmpty && u.email.toLowerCase() == email.toLowerCase()) {
        return true;
      }
      if (_normUsername(u.username) == _normUsername(username)) return true;
    }
    return false;
  }

  Future<bool> registerUser(UserAccount user) async {
    final p = await _prefs;
    final users = _readUsers(p);
    if (_isTaken(users, user.email, user.username)) return false;
    users.add(user);
    await _writeUsers(p, users);
    return true;
  }

  Future<UserAccount?> loginUser(String login, String password) async {
    final users = _readUsers(await _prefs);
    final loginClean = _normUsername(login);
    for (final u in users) {
      final matchEmail = u.email.toLowerCase() == login.toLowerCase();
      final matchUsername = _normUsername(u.username) == loginClean;
      if ((matchEmail || matchUsername) && u.password == password) {
        return u;
      }
    }
    return null;
  }

  /// Сохраняет правки профиля. Возвращает текст ошибки или null, если
  /// всё сохранено.
  Future<String?> updateCurrentUser({
    required String name,
    required String email,
    required String username,
  }) async {
    final p = await _prefs;
    final user = _readCurrentUser(p);
    if (user == null) return 'Пользователь не найден';
    final users = _readUsers(p);
    if (_isTaken(users, email, username, exceptId: user.id)) {
      return 'Такой email или username уже занят';
    }
    final updated = user.copyWith(name: name, email: email, username: username);
    final index = users.indexWhere((u) => u.id == user.id);
    if (index >= 0) users[index] = updated;
    await _writeUsers(p, users);
    await p.setString(_kCurrentUser, jsonEncode(updated.toJson()));
    return null;
  }

  /// Удаляет аккаунт текущего пользователя и все его данные в
  /// SharedPreferences (аватар, переписку, превью чатов). Возвращает id
  /// удалённого пользователя или null, если никто не вошёл.
  Future<String?> deleteCurrentAccount() async {
    final p = await _prefs;
    final user = _readCurrentUser(p);
    if (user == null) return null;

    final users = _readUsers(p)..removeWhere((u) => u.id == user.id);
    await _writeUsers(p, users);

    final messagesPrefix = _scoped(user.id, _kMessagesPrefix);
    final ownKeys = {
      _scoped(user.id, _kAvatarPath),
      _scoped(user.id, _kChatInfo),
      _scoped(user.id, _kDeletedIds),
      _scoped(user.id, _kNameOverrides),
    };
    final keys = p
        .getKeys()
        .where((k) => ownKeys.contains(k) || k.startsWith(messagesPrefix))
        .toList();
    for (final key in keys) {
      await p.remove(key);
    }

    await p.setBool(_kLoggedIn, false);
    await p.remove(_kCurrentUser);
    return user.id;
  }

  // ---------- Переписка ----------

  Future<List<Message>> loadMessages(String contactId) async {
    final p = await _prefs;
    final key = _userKey(p, '$_kMessagesPrefix$contactId');
    final raw = key == null ? null : p.getStringList(key);
    if (raw == null) return [];
    final result = <Message>[];
    for (final s in raw) {
      try {
        result.add(Message.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // повреждённое сообщение пропускаем
      }
    }
    return result;
  }

  Future<void> saveMessages(String contactId, List<Message> messages) async {
    final p = await _prefs;
    final key = _userKey(p, '$_kMessagesPrefix$contactId');
    if (key == null) return;
    await p.setStringList(
      key,
      messages.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  // ---------- Превью чатов ----------

  Map<String, dynamic> _readChatInfo(SharedPreferences p, String key) {
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<Map<String, Map<String, dynamic>>> getChatInfo() async {
    final p = await _prefs;
    final key = _userKey(p, _kChatInfo);
    if (key == null) return {};
    return _readChatInfo(p, key).map((k, v) => MapEntry(
        k, v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{}));
  }

  Future<void> markChatOpened(String contactId) async {
    final p = await _prefs;
    final key = _userKey(p, _kChatInfo);
    if (key == null) return;
    final map = _readChatInfo(p, key);
    final existing = map[contactId] is Map
        ? Map<String, dynamic>.from(map[contactId] as Map)
        : <String, dynamic>{};
    map[contactId] = {
      'text': existing['text'] ?? '',
      'time': existing['time'] ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    await p.setString(key, jsonEncode(map));
  }

  Future<void> updateChatPreview(
      String contactId, String text, String time) async {
    final p = await _prefs;
    final key = _userKey(p, _kChatInfo);
    if (key == null) return;
    final map = _readChatInfo(p, key);
    map[contactId] = {
      'text': text,
      'time': time,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    await p.setString(key, jsonEncode(map));
  }

  /// Удаляет переписку и превью чата вместе с контактом.
  Future<void> deleteChatData(String contactId) async {
    final p = await _prefs;
    final messagesKey = _userKey(p, '$_kMessagesPrefix$contactId');
    if (messagesKey != null) await p.remove(messagesKey);
    final infoKey = _userKey(p, _kChatInfo);
    if (infoKey == null) return;
    final map = _readChatInfo(p, infoKey);
    if (map.remove(contactId) != null) {
      await p.setString(infoKey, jsonEncode(map));
    }
  }

  // ---------- Аватар ----------

  Future<String?> getAvatarPath() async {
    final p = await _prefs;
    final key = _userKey(p, _kAvatarPath);
    return key == null ? null : p.getString(key);
  }

  Future<void> setAvatarPath(String path) async {
    final p = await _prefs;
    final key = _userKey(p, _kAvatarPath);
    if (key == null) return;
    await p.setString(key, path);
  }

  // ---------- Тема ----------

  Future<bool> isDarkMode() async {
    final p = await _prefs;
    return p.getBool(_kThemeMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await _prefs;
    await p.setBool(_kThemeMode, value);
  }

  // ---------- Правки контактов из старых версий ----------

  /// Удалённые id и переименования, которые старые версии хранили здесь.
  /// Нужны один раз — для переноса в contacts_<id>.json.
  Future<({Set<String> deletedIds, Map<String, String> nameOverrides})>
      getLegacyContactEdits(String userId) async {
    final p = await _prefs;
    final deleted =
        (p.getStringList(_scoped(userId, _kDeletedIds)) ?? const <String>[])
            .toSet();
    final overrides = <String, String>{};
    final raw = p.getString(_scoped(userId, _kNameOverrides));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) => overrides['$k'] = '$v');
        }
      } catch (_) {
        // повреждённые старые данные просто игнорируем
      }
    }
    return (deletedIds: deleted, nameOverrides: overrides);
  }

  Future<void> clearLegacyContactEdits(String userId) async {
    final p = await _prefs;
    await p.remove(_scoped(userId, _kDeletedIds));
    await p.remove(_scoped(userId, _kNameOverrides));
  }

  // ---------- Миграция ----------

  /// Старые версии хранили аватар, переписку и превью чатов общими ключами,
  /// из-за чего новый пользователь видел данные предыдущего. Один раз
  /// переносим эти данные последнему вошедшему пользователю (он и был их
  /// владельцем), а общие ключи удаляем.
  Future<void> migrateLegacyData() async {
    final p = await _prefs;
    if (p.getBool(_kScopedMigrated) ?? false) return;

    // Фиксируем id у старых аккаунтов, чтобы он не зависел от смены email.
    await _writeUsers(p, _readUsers(p));
    final current = _readCurrentUser(p);
    if (current != null) {
      await p.setString(_kCurrentUser, jsonEncode(current.toJson()));
    }

    final legacyKeys = p
        .getKeys()
        .where((k) =>
            k == _kAvatarPath ||
            k == _kChatInfo ||
            k == _kDeletedIds ||
            k == _kNameOverrides ||
            k.startsWith(_kMessagesPrefix))
        .toList();
    for (final key in legacyKeys) {
      final value = p.get(key);
      if (current != null) {
        final newKey = _scoped(current.id, key);
        if (value is String) {
          await p.setString(newKey, value);
        } else if (value is List) {
          await p.setStringList(newKey, value.cast<String>());
        }
      }
      await p.remove(key);
    }
    await p.setBool(_kScopedMigrated, true);
  }
}
