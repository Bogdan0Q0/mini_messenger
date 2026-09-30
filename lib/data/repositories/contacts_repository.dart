import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../storage/prefs_storage.dart';

class ContactsRepository {
  final _storage = PrefsStorage();

  Future<List<Contact>> fetchContacts() async {
    List<Contact> raw = kFallbackContacts;
    try {
      final res = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        raw = data.take(10).map((j) => Contact.fromJson(j)).toList();
      }
    } catch (e) {
      raw = kFallbackContacts;
    }

    final deleted = await _storage.getDeletedIds();
    final overrides = await _storage.getNameOverrides();

    final result = <Contact>[];
    for (final c in raw) {
      if (deleted.contains(c.id)) continue;
      final newName = overrides[c.id];
      if (newName != null && newName.isNotEmpty) {
        result.add(Contact(
          id: c.id,
          name: newName,
          username: c.username,
          initials: _initialsFor(newName),
          color: c.color,
        ));
      } else {
        result.add(c);
      }
    }
    return result;
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(' ');
    final buf = StringBuffer();
    for (var i = 0; i < parts.length && i < 2; i++) {
      if (parts[i].isNotEmpty) buf.write(parts[i][0]);
    }
    final s = buf.toString().toUpperCase();
    return s.isEmpty ? 'U' : s;
  }
}
