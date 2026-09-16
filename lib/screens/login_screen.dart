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
  final loginCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final storage = PrefsStorage();
  String error = '';

  @override
  void dispose() {
    loginCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  bool isValidEmail(String s) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);
  }

  Future<void> login() async {
    final login = loginCtrl.text.trim();
    final pass = passCtrl.text;

    if (login.isEmpty || pass.isEmpty) {
      setState(() => error = 'Заполните все поля');
      return;
    }
    if (pass.length < 6) {
      setState(() => error = 'Пароль должен быть не короче 6 символов');
      return;
    }
    if (login.contains('@') && !isValidEmail(login)) {
      setState(() => error = 'Некорректный email');
      return;
    }

    setState(() => error = '');
    await storage.setLoggedIn(true);
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
                child:
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('MiniChat',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Общайтесь просто и удобно',
                  style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 42),
              TextField(
                controller: loginCtrl,
                decoration:
                    const InputDecoration(hintText: 'Email или username'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Пароль'),
              ),
              if (error.isNotEmpty) const SizedBox(height: 10),
              if (error.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(error,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Забыли пароль',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Войти', onPressed: login),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Нет аккаунта',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Зарегистрироваться',
                        style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
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
