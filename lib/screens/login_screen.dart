import 'package:flutter/material.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';
import 'chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _storage = PrefsStorage();
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final login = _loginCtrl.text.trim();
    final pass = _passCtrl.text;

    if (login.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Пароль должен быть не короче 6 символов');
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    final user = await _storage.loginUser(login, pass);
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Неверный логин или пароль';
      });
      return;
    }
    await _storage.setCurrentUser(user);
    await _storage.setLoggedIn(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.chat_bubble,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text('MiniChat',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Общайтесь просто и удобно',
                  style:
                      TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 42),
              TextField(
                controller: _loginCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                    hintText: 'Email или @username'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Пароль'),
              ),
              if (_error.isNotEmpty) const SizedBox(height: 10),
              if (_error.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(label: 'Войти', onPressed: _login),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Нет аккаунта',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Зарегистрироваться',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
