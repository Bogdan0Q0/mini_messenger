import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/user_account.dart';

class PrefsStorage {
  static const _kLoggedIn = 'logged_in';
  static const _kRegisteredUsers = 'registered_users';
  static const _kCurrentUser = 'current_user';
  static const _kAvatarPath = 'avatar_path';
  static const _kThemeMode = 'theme_mode';
  static const _kDeletedIds = 'deleted_ids';
  static const _kNameOverrides = 'name_overrides';
  static const _kChatInfo = 'chat_info';

  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) ?? false;
  }

  Future<void> setLoggedIn(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, value);
  }

  Future<List<UserAccount>> _getRegisteredUsers() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kRegisteredUsers) ?? [];
    return raw
        .map((s) => UserAccount.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<bool> registerUser(UserAccount user) async {
    final users = await _getRegisteredUsers();
    for (final u in users) {
      if (u.email.toLowerCase() == user.email.toLowerCase()) return false;
      if (u.username.toLowerCase().replaceAll('@', '') ==
          user.username.toLowerCase().replaceAll('@', '')) {
        return false;
      }
    }
    users.add(user);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _kRegisteredUsers,
      users.map((u) => jsonEncode(u.toJson())).toList(),
    );
    return true;
  }

  Future<UserAccount?> loginUser(String login, String password) async {
    final users = await _getRegisteredUsers();
    final loginClean = login.toLowerCase().replaceAll('@', '');
    for (final u in users) {
      final matchEmail = u.email.toLowerCase() == login.toLowerCase();
      final matchUsername =
          u.username.toLowerCase().replaceAll('@', '') == loginClean;
      if ((matchEmail || matchUsername) && u.password == password) {
        return u;
      }
    }
    return null;
  }

  Future<void> setCurrentUser(UserAccount user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrentUser, jsonEncode(user.toJson()));
  }

  Future<UserAccount?> getCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCurrentUser);
    if (raw == null) return null;
    return UserAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> updateCurrentUser({
    required String name,
    required String email,
    required String username,
  }) async {
    final user = await getCurrentUser();
    if (user == null) return;
    final updated = UserAccount(
      name: name,
      email: email,
      username: username,
      password: user.password,
    );
    final users = await _getRegisteredUsers();
    for (var i = 0; i < users.length; i++) {
      if (users[i].email.toLowerCase() == user.email.toLowerCase() &&
          users[i].username.toLowerCase() == user.username.toLowerCase()) {
        users[i] = updated;
        break;
      }
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _kRegisteredUsers,
      users.map((u) => jsonEncode(u.toJson())).toList(),
    );
    await p.setString(_kCurrentUser, jsonEncode(updated.toJson()));
  }

  Future<List<Message>> loadMessages(String contactId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('messages_$contactId');
    if (raw == null || raw.isEmpty) return [];
    return raw
        .map((s) => Message.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMessages(String contactId, List<Message> messages) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      'messages_$contactId',
      messages.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  Future<List<String>> getDeletedIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_kDeletedIds) ?? [];
  }

  Future<void> addDeletedId(String id) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(_kDeletedIds) ?? [];
    if (!ids.contains(id)) ids.add(id);
    await p.setStringList(_kDeletedIds, ids);
  }

  Future<Map<String, String>> getNameOverrides() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kNameOverrides);
    if (raw == null || raw.isEmpty) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> setNameOverride(String id, String name) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kNameOverrides);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    map[id] = name;
    await p.setString(_kNameOverrides, jsonEncode(map));
  }

  Future<Map<String, Map<String, dynamic>>> getChatInfo() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kChatInfo);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
  }

  Future<void> markChatOpened(String contactId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kChatInfo);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final existing =
        map[contactId] != null ? Map<String, dynamic>.from(map[contactId]) : {};
    map[contactId] = {
      'text': existing['text'] ?? '',
      'time': existing['time'] ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    await p.setString(_kChatInfo, jsonEncode(map));
  }

  Future<void> updateChatPreview(
      String contactId, String text, String time) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kChatInfo);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[contactId] = {
      'text': text,
      'time': time,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    await p.setString(_kChatInfo, jsonEncode(map));
  }

  Future<String?> getAvatarPath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAvatarPath);
  }

  Future<void> setAvatarPath(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAvatarPath, path);
  }

  Future<bool> isDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kThemeMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kThemeMode, value);
  }
}
