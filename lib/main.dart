import 'package:flutter/material.dart';
import 'app.dart';
import 'data/storage/prefs_storage.dart';
import 'state/session_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsStorage().migrateLegacyData();
  final theme = ThemeController();
  final session = SessionController();
  await Future.wait([theme.load(), session.load()]);
  runApp(MiniChatApp(theme: theme, session: session));
}
