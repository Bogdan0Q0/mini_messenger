import 'package:flutter/foundation.dart';
import '../storage/contacts_file_storage.dart';
import '../storage/media_storage.dart';
import '../storage/prefs_storage.dart';

/// Операции над аккаунтом целиком.
class AccountRepository {
  AccountRepository({
    PrefsStorage? prefs,
    ContactsFileStorage? contactsFile,
    MediaStorage? media,
  })  : _prefs = prefs ?? PrefsStorage(),
        _contactsFile = contactsFile ?? ContactsFileStorage(),
        _media = media ?? MediaStorage();

  final PrefsStorage _prefs;
  final ContactsFileStorage _contactsFile;
  final MediaStorage _media;

  /// Удаляет текущий аккаунт вместе со всеми данными: настройками,
  /// перепиской, файлом контактов и фото. После этого пользователь
  /// считается вышедшим.
  Future<void> deleteCurrentAccount() async {
    final userId = await _prefs.deleteCurrentAccount();
    if (userId == null) return;
    try {
      await _contactsFile.delete(userId);
      await _media.deleteUser(userId);
    } catch (e) {
      // Аккаунт уже удалён; оставшиеся файлы недоступны без него.
      debugPrint('Не удалось удалить файлы пользователя $userId ($e)');
    }
  }
}
