import 'package:flutter/material.dart';
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
  final nameCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  final storage = PrefsStorage();
  String error = '';

  @override
  void dispose() {
    nameCtrl.dispose();
    userCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

  bool isValidEmail(String s) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);
  }

  Future<void> register() async {
    final name = nameCtrl.text.trim();
    final user = userCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    final pass2 = pass2Ctrl.text;

    if (name.isEmpty || user.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => error = 'Заполните все поля');
      return;
    }
    if (name.length < 2) {
      setState(() => error = 'Имя должно быть не короче 2 символов');
      return;
    }
    if (user.length < 3 || !user.startsWith('@')) {
      setState(() => error = 'Username должен начинаться с @');
      return;
    }
    if (!isValidEmail(email)) {
      setState(() => error = 'Некорректный email');
      return;
    }
    if (pass.length < 8) {
      setState(() => error = 'Пароль должен быть не короче 8 символов');
      return;
    }
    if (pass != pass2) {
      setState(() => error = 'Пароли не совпадают');
      return;
    }

    setState(() => error = '');
    await storage.setLoggedIn(true);
    await storage.saveProfile(name: name, email: email, username: user);
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
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
                        label: 'Имя', hint: 'Ваше имя', controller: nameCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Username',
                        hint: '@username',
                        controller: userCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Email',
                        hint: 'email@example.com',
                        controller: emailCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Пароль',
                        hint: 'Минимум 8 символов',
                        obscure: true,
                        controller: passCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Повторите пароль',
                        hint: 'Повторите пароль',
                        obscure: true,
                        controller: pass2Ctrl),
                  ],
                ),
              ),
              if (error.isNotEmpty) const SizedBox(height: 12),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(error,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                    PrimaryButton(label: 'Создать аккаунт', onPressed: register),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Уже есть аккаунт',
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
