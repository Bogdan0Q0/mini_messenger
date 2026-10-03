import 'package:flutter/material.dart';
import '../../utils/text_utils.dart';

class Contact {
  final String id;
  final String name;
  final String username;
  final String initials;
  final Color color;

  const Contact({
    required this.id,
    required this.name,
    required this.username,
    required this.initials,
    required this.color,
  });

  static const _avatarColors = [
    Color(0xFF3478F6),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFFFF3B30),
  ];

  /// Контакт из ответа REST API (jsonplaceholder.typicode.com/users).
  factory Contact.fromApi(Map<String, dynamic> j) {
    final id = '${j['id'] ?? ''}';
    final rawName = j['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'User';
    final rawUser = j['username'];
    final username = rawUser is String ? rawUser : 'user';
    final colorIndex = (int.tryParse(id) ?? 0) % _avatarColors.length;
    return Contact(
      id: id,
      name: name,
      username: '@$username',
      initials: initialsOf(name),
      color: _avatarColors[colorIndex],
    );
  }

  /// Контакт из локального файла contacts.json.
  factory Contact.fromJson(Map<String, dynamic> j) {
    final rawName = j['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'User';
    final rawInitials = j['initials'];
    return Contact(
      id: '${j['id']}',
      name: name,
      username: (j['username'] as String?) ?? '@user',
      initials: rawInitials is String && rawInitials.isNotEmpty
          ? rawInitials
          : initialsOf(name),
      color: Color((j['color'] as int?) ?? _avatarColors.first.toARGB32()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'initials': initials,
        'color': color.toARGB32(),
      };

  /// Копия с новым именем; инициалы пересчитываются.
  Contact withName(String newName) => Contact(
        id: id,
        name: newName,
        username: username,
        initials: initialsOf(newName),
        color: color,
      );

  /// Подходит ли контакт под поисковый запрос (по имени или @username).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || username.toLowerCase().contains(q);
  }
}

const List<Contact> kFallbackContacts = [
  Contact(id: '1', name: 'Алексей Петров', username: '@alex', initials: 'АП', color: Color(0xFF3478F6)),
  Contact(id: '2', name: 'Максим Иванов', username: '@max', initials: 'МИ', color: Color(0xFF34C759)),
  Contact(id: '3', name: 'Анна Смирнова', username: '@anna', initials: 'АС', color: Color(0xFFFF9500)),
  Contact(id: '4', name: 'Дмитрий', username: '@dmitry', initials: 'Д', color: Color(0xFFAF52DE)),
  Contact(id: '5', name: 'Мария', username: '@maria', initials: 'М', color: Color(0xFFFF3B30)),
];
