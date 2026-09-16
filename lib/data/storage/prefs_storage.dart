import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class PrefsStorage {
  static const kLoggedIn = 'logged_in';
  static const kName = 'profile_name';
  static const kEmail = 'profile_email';
  static const kUsername = 'profile_username';

  Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    final value = p.getBool(kLoggedIn);
    return value != null && value;
  }

  Future<void> setLoggedIn(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kLoggedIn, value);
  }

  Future<Map<String, String>> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    
    
    
    return {
      'name': p.getString(kName) ?? '',
      'email': p.getString(kEmail) ?? '',
      'username': p.getString(kUsername) ?? '@alex',
    };
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    String username = '',
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kName, name);
    await p.setString(kEmail, email);
    if (username.isNotEmpty) await p.setString(kUsername, username);
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
}
