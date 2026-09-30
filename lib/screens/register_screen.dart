import 'package:flutter/material.dart';
import '../data/models/user_account.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/nav_header.dart';
import '../widgets/primary_button.dart';
import 'chat_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  final _storage = PrefsStorage();
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final user = _userCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;

    if (name.isEmpty || user.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    if (name.length < 2) {
      setState(() => _error = 'Имя должно быть не короче 2 символов');
      return;
    }
    if (user.length < 3 || !user.startsWith('@')) {
      setState(() =>
          _error = 'Username должен начинаться с @ и быть не короче 3 символов');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Некорректный email');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Пароль должен быть не короче 8 символов');
      return;
    }
    if (pass != pass2) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    final account = UserAccount(
      name: name,
      username: user,
      email: email,
      password: pass,
    );
    final ok = await _storage.registerUser(account);
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Пользователь с таким email или username уже существует';
      });
      return;
    }
    await _storage.setCurrentUser(account);
    await _storage.setLoggedIn(true);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChatListScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              NavHeader(
                  title: 'Создание аккаунта',
                  onBack: () => Navigator.pop(context)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Заполните данные для регистрации',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AppTextField(
                        label: 'Имя',
                        hint: 'Ваше имя',
                        controller: _nameCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Username',
                        hint: '@username',
                        controller: _userCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Email',
                        hint: 'email@example.com',
                        controller: _emailCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Пароль',
                        hint: 'Минимум 8 символов',
                        obscure: true,
                        controller: _passCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Повторите пароль',
                        hint: 'Повторите пароль',
                        obscure: true,
                        controller: _pass2Ctrl),
                  ],
                ),
              ),
              if (_error.isNotEmpty) const SizedBox(height: 12),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'Создать аккаунт', onPressed: _register),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Уже есть аккаунт',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Войти',
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
