import 'package:flutter/material.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/nav_header.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final storage = PrefsStorage();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final profile = await storage.loadProfile();
    nameCtrl.text = profile['name'] ?? '';
    emailCtrl.text = profile['email'] ?? '';
    if (mounted) setState(() => loaded = true);
  }

  bool isValidEmail(String s) {
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);
  }

  Future<void> save() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();

    if (name.isEmpty) {
      showError('Имя не может быть пустым');
      return;
    }
    if (name.length < 2) {
      showError('Имя должно быть не короче 2 символов');
      return;
    }
    if (email.isNotEmpty && !isValidEmail(email)) {
      showError('Некорректный email');
      return;
    }

    await storage.saveProfile(name: name, email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Профиль сохранён'),
          backgroundColor: AppColors.primary),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> logout() async {
    await storage.setLoggedIn(false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              NavHeader(
                title: 'Профиль',
                onBack: () => Navigator.pop(context),
                right: TextButton(
                  onPressed: save,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Сохранить',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 12),
              const CustomAvatar(
                  initials: 'АП', color: AppColors.primary, size: 88),
              const SizedBox(height: 14),
              const Text('Алексей',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('@alex',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Имя',
                      hint: 'Ваше имя',
                      controller: nameCtrl,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Email',
                      hint: 'email@example.com',
                      controller: emailCtrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Column(
                  children: [
                    SettingRow(
                        icon: Icons.notifications_none,
                        label: 'Уведомления'),
                    Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 64,
                        color: AppColors.divider),
                    SettingRow(
                        icon: Icons.brightness_6_outlined, label: 'Тема'),
                    Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 64,
                        color: AppColors.divider),
                    SettingRow(
                        icon: Icons.info_outline, label: 'О приложении'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: logout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Выйти',
                        style: TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const SettingRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.bubbleIn,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textPrimary)),
          ),
          const Icon(Icons.chevron_right,
              size: 20, color: Color(0xFFB0B4BC)),
        ],
      ),
    );
  }
}
