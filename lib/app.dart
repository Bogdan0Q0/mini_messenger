import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/chat_list_screen.dart';
import 'screens/login_screen.dart';
import 'state/session_controller.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';

/// Корень приложения. Общее состояние (тема и сессия) создаётся здесь и
/// раздаётся через Provider; уже загруженные контроллеры можно передать
/// снаружи, чтобы не мигала тема при запуске.
class MiniChatApp extends StatelessWidget {
  const MiniChatApp({super.key, this.theme, this.session});

  final ThemeController? theme;
  final SessionController? session;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => theme ?? (ThemeController()..load()),
        ),
        ChangeNotifierProvider<SessionController>(
          create: (_) => session ?? (SessionController()..load()),
        ),
      ],
      child: const _MaterialShell(),
    );
  }
}

class _MaterialShell extends StatelessWidget {
  const _MaterialShell();

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<ThemeController, bool>((t) => t.isDark);
    return MaterialApp(
      title: 'MiniChat',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        // Значки статус-бара и панели навигации подстраиваются под тему.
        final palette = context.palette;
        final darkSurface = Theme.of(context).brightness == Brightness.dark;
        final icons = darkSurface ? Brightness.light : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: icons,
            statusBarBrightness: darkSurface ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: palette.bg,
            systemNavigationBarIconBrightness: icons,
          ),
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

/// Выбирает стартовый экран по состоянию сессии.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<SessionController, bool?>((s) => s.loggedIn);
    if (loggedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return loggedIn ? const ChatListScreen() : const LoginScreen();
  }
}
