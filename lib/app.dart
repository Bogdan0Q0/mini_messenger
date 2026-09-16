import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/chat_list_screen.dart';

class MiniChatApp extends StatelessWidget {
  const MiniChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniChat',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool loaded = false;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    check();
  }

  Future<void> check() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('logged_in');
    setState(() {
      loggedIn = value != null && value;
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return loggedIn ? const ChatListScreen() : const LoginScreen();
  }
}
