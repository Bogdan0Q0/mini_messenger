import 'package:flutter/foundation.dart';
import '../data/storage/prefs_storage.dart';

/// Состояние темы оформления (Provider). Читается при запуске, меняется
/// переключателем в профиле и сохраняется в [PrefsStorage].
class ThemeController extends ChangeNotifier {
  ThemeController({PrefsStorage? storage})
      : _storage = storage ?? PrefsStorage();

  final PrefsStorage _storage;
  bool _isDark = false;

  bool get isDark => _isDark;

  Future<void> load() async {
    _isDark = await _storage.isDarkMode();
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    await _storage.setDarkMode(value);
  }
}
