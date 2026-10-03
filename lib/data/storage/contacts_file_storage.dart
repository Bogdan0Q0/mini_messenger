import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/contact.dart';

/// Хранит список контактов каждого пользователя в своём JSON-файле
/// `contacts_<id пользователя>.json` во внутренней папке приложения.
class ContactsFileStorage {
  ContactsFileStorage({Future<Directory> Function()? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<File> _file(String userId) async {
    final dir = await _directoryProvider();
    return File('${dir.path}${Platform.pathSeparator}contacts_$userId.json');
  }

  /// Возвращает контакты из файла или `null`, если файла нет
  /// либо он повреждён.
  Future<List<Contact>?> read(String userId) async {
    try {
      final file = await _file(userId);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((m) => Contact.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('contacts_$userId.json: не удалось прочитать ($e)');
      return null;
    }
  }

  /// Удаляет файл контактов пользователя.
  Future<void> delete(String userId) async {
    final file = await _file(userId);
    if (await file.exists()) await file.delete();
  }

  /// Перезаписывает файл целиком. Сначала пишется временный файл, потом он
  /// переименовывается, чтобы сбой посреди записи не повредил основной файл.
  Future<void> write(String userId, List<Contact> contacts) async {
    final file = await _file(userId);
    final tmp = File('${file.path}.tmp');
    final json = const JsonEncoder.withIndent('  ')
        .convert(contacts.map((c) => c.toJson()).toList());
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }
}
