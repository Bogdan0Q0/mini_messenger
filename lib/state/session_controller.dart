import 'package:flutter/foundation.dart';
import '../data/storage/prefs_storage.dart';

/// Состояние сессии (Provider): вошёл ли пользователь. Пока данные не
/// прочитаны, [loggedIn] равен null — [AuthGate] показывает индикатор.
class SessionController extends ChangeNotifier {
  SessionController({PrefsStorage? storage})
      : _storage = storage ?? PrefsStorage();

  final PrefsStorage _storage;
  bool? _loggedIn;

  bool? get loggedIn => _loggedIn;

  Future<void> load() async {
    _loggedIn = await _storage.isLoggedIn();
    notifyListeners();
  }
}
