import 'package:flutter/material.dart';

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

  factory Contact.fromJson(Map<String, dynamic> j) {
    final rawName = j['name'];
    final name = (rawName is String) ? rawName : 'User';
    final parts = name.split(' ');
    final initialsBuffer = StringBuffer();
    for (var i = 0; i < parts.length && i < 2; i++) {
      final p = parts[i];
      if (p.isNotEmpty) initialsBuffer.write(p[0]);
    }
    final initialsRaw = initialsBuffer.toString().toUpperCase();
    final initials = initialsRaw.isEmpty ? 'U' : initialsRaw;
    final colors = [
      const Color(0xFF3478F6),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFAF52DE),
      const Color(0xFFFF3B30),
    ];
    final rawId = j['id'];
    final idInt = (rawId is int) ? rawId : 1;
    final rawUser = j['username'];
    final userStr = (rawUser is String) ? rawUser : 'user';
    return Contact(
      id: rawId.toString(),
      name: name,
      username: '@$userStr',
      initials: initials,
      color: colors[idInt % colors.length],
    );
  }
}

const List<Contact> kFallbackContacts = [
  Contact(id: '1', name: 'Алексей Петров', username: '@alex', initials: 'АП', color: Color(0xFF3478F6)),
  Contact(id: '2', name: 'Максим Иванов', username: '@max', initials: 'МИ', color: Color(0xFF34C759)),
  Contact(id: '3', name: 'Анна Смирнова', username: '@anna', initials: 'АС', color: Color(0xFFFF9500)),
  Contact(id: '4', name: 'Дмитрий', username: '@dmitry', initials: 'Д', color: Color(0xFFAF52DE)),
  Contact(id: '5', name: 'Мария', username: '@maria', initials: 'М', color: Color(0xFFFF3B30)),
];
