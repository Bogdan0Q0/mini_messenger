import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  darkModeNotifier.value = prefs.getBool('theme_mode') ?? false;
  runApp(const MiniChatApp());
}
