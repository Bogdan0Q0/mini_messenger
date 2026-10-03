import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Постоянное хранилище фото (аватар и снимки из чатов).
///
/// image_picker отдаёт файл во временной папке, которую система может
/// очистить, поэтому выбранное фото копируется в папку приложения:
/// `media/<id пользователя>/<папка>/<файл>`.
class MediaStorage {
  MediaStorage({Future<Directory> Function()? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  /// Папка с фото одного чата.
  static String chatFolder(String contactId) => 'chat_$contactId';

  static const avatarFolder = 'avatar';

  Future<Directory> _folder(String userId, String folder) async {
    final root = await _directoryProvider();
    final sep = Platform.pathSeparator;
    return Directory('${root.path}${sep}media$sep$userId$sep$folder');
  }

  /// Копирует фото в постоянное хранилище и возвращает новый путь.
  /// С [replaceExisting] остальные файлы папки удаляются (так хранится аватар).
  Future<String> importImage(
    String sourcePath, {
    required String userId,
    required String folder,
    bool replaceExisting = false,
  }) async {
    final dir = await _folder(userId, folder);
    await dir.create(recursive: true);
    final old = replaceExisting
        ? await dir.list().toList()
        : <FileSystemEntity>[];
    final name = '${DateTime.now().microsecondsSinceEpoch}'
        '${_extensionOf(sourcePath)}';
    final target = File('${dir.path}${Platform.pathSeparator}$name');
    await File(sourcePath).copy(target.path);
    for (final entity in old) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // не удалось стереть старый файл — не страшно
      }
    }
    return target.path;
  }

  Future<void> deleteFolder(String userId, String folder) async {
    final dir = await _folder(userId, folder);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Удаляет все фото пользователя (аватар и снимки из всех чатов).
  Future<void> deleteUser(String userId) async {
    final root = await _directoryProvider();
    final dir = Directory(
        '${root.path}${Platform.pathSeparator}media${Platform.pathSeparator}$userId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static String _extensionOf(String path) {
    final name = path.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || name.length - dot > 6) return '.jpg';
    return name.substring(dot).toLowerCase();
  }
}
