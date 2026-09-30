import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app.dart';
import '../data/models/user_account.dart';
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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _storage = PrefsStorage();
  String? _avatarPath;
  UserAccount? _user;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await _storage.getCurrentUser();
    final avatar = await _storage.getAvatarPath();
    if (!mounted) return;
    setState(() {
      _user = user;
      _nameCtrl.text = user?.name ?? '';
      _emailCtrl.text = user?.email ?? '';
      _usernameCtrl.text = user?.username ?? '';
      _avatarPath = avatar;
      _loaded = true;
    });
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _storage.setAvatarPath(picked.path);
      if (!mounted) return;
      setState(() => _avatarPath = picked.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Аватар обновлён'),
            backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Не удалось выбрать фото: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleDark(bool value) async {
    await _storage.setDarkMode(value);
    darkModeNotifier.value = value;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final username = _usernameCtrl.text.trim();

    if (name.isEmpty) {
      _showError('Имя не может быть пустым');
      return;
    }
    if (name.length < 2) {
      _showError('Имя должно быть не короче 2 символов');
      return;
    }
    if (username.isEmpty) {
      _showError('Username не может быть пустым');
      return;
    }
    if (!username.startsWith('@')) {
      _showError('Username должен начинаться с @');
      return;
    }
    if (email.isNotEmpty && !_isValidEmail(email)) {
      _showError('Некорректный email');
      return;
    }

    await _storage.updateCurrentUser(
        name: name, email: email, username: username);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Профиль сохранён'),
          backgroundColor: AppColors.primary),
    );
    await _load();
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _logout() async {
    await _storage.setLoggedIn(false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _initialsFrom(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    final buf = StringBuffer();
    for (var i = 0; i < parts.length && i < 2; i++) {
      if (parts[i].isNotEmpty) buf.write(parts[i][0]);
    }
    final s = buf.toString().toUpperCase();
    return s.isEmpty ? 'U' : s;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final initials = _initialsFrom(_nameCtrl.text);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              NavHeader(
                title: 'Профиль',
                onBack: () => Navigator.pop(context),
                right: TextButton(
                  onPressed: _save,
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
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CustomAvatar(
                      initials: initials,
                      color: AppColors.primary,
                      size: 100,
                      imagePath: _avatarPath,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickAvatar,
                child: const Text('Изменить фото',
                    style: TextStyle(
                        color: AppColors.primary, fontSize: 14)),
              ),
              Text(_nameCtrl.text.isEmpty ? 'Без имени' : _nameCtrl.text,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(
                  _usernameCtrl.text.isEmpty
                      ? '@user'
                      : _usernameCtrl.text,
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
                        controller: _nameCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Username',
                        hint: '@username',
                        controller: _usernameCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Email',
                        hint: 'email@example.com',
                        controller: _emailCtrl),
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
                child: ValueListenableBuilder<bool>(
                  valueListenable: darkModeNotifier,
                  builder: (_, isDark, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.bubbleIn,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.brightness_6_outlined,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Тёмная тема',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                        ),
                        Switch(
                          value: isDark,
                          onChanged: _toggleDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.divider),
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
