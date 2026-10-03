import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/models/user_account.dart';
import '../data/repositories/account_repository.dart';
import '../data/storage/media_storage.dart';
import '../data/storage/prefs_storage.dart';
import '../state/theme_controller.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
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
  final _media = MediaStorage();
  final _account = AccountRepository();
  String? _avatarPath;

  /// Выбранное, но ещё не сохранённое фото: применится по кнопке «Сохранить».
  String? _pendingAvatarPath;
  bool _deleting = false;
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
      _pendingAvatarPath = null;
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
      if (picked == null || !mounted) return;
      // Пока только предпросмотр: на диск и в профиль фото попадёт
      // по кнопке «Сохранить».
      setState(() => _pendingAvatarPath = picked.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Фото выбрано. Нажмите «Сохранить», чтобы применить'),
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

  Future<void> _toggleDark(bool value) =>
      context.read<ThemeController>().setDark(value);

  Future<void> _save() async {
    // Убираем курсор и клавиатуру: после нажатия «Сохранить» ввод закончен.
    FocusManager.instance.primaryFocus?.unfocus();
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
    if (username.length < 3 || !username.startsWith('@')) {
      _showError('Username должен начинаться с @ и быть не короче 3 символов');
      return;
    }
    if (!_isValidEmail(email)) {
      _showError('Некорректный email');
      return;
    }

    final error = await _storage.updateCurrentUser(
        name: name, email: email, username: username);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
      return;
    }
    final pending = _pendingAvatarPath;
    if (pending != null) {
      try {
        await _applyAvatar(pending);
      } catch (_) {
        if (!mounted) return;
        _showError('Профиль сохранён, но фото применить не удалось');
        await _load();
        return;
      }
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Профиль сохранён'),
          backgroundColor: AppColors.primary),
    );
    await _load();
  }

  /// Копирует выбранное фото в папку приложения (временный файл
  /// image_picker могут стереть) и делает его аватаром; прежний заменяется.
  Future<void> _applyAvatar(String sourcePath) async {
    final userId = await _storage.getCurrentUserId();
    if (userId == null) return;
    final savedPath = await _media.importImage(
      sourcePath,
      userId: userId,
      folder: MediaStorage.avatarFolder,
      replaceExisting: true,
    );
    await _storage.setAvatarPath(savedPath);
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _logout() async {
    await _storage.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmDeleteProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить профиль?'),
        content: const Text(
            'Аккаунт, вся переписка, контакты и фото будут удалены без '
            'возможности восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена',
                style: TextStyle(color: context.palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || _deleting) return;
    setState(() => _deleting = true);
    try {
      await _account.deleteCurrentAccount();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showError('Не удалось удалить профиль');
      return;
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final initials = initialsOf(_nameCtrl.text);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      imagePath: _pendingAvatarPath ?? _avatarPath,
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
                      color: context.palette.textPrimary)),
              const SizedBox(height: 2),
              Text(
                  _usernameCtrl.text.isEmpty
                      ? '@user'
                      : _usernameCtrl.text,
                  style: TextStyle(
                      fontSize: 14, color: context.palette.textSecondary)),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AppTextField(
                        label: 'Имя',
                        hint: 'Ваше имя',
                        textInputAction: TextInputAction.next,
                        controller: _nameCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Username',
                        hint: '@username',
                        textInputAction: TextInputAction.next,
                        controller: _usernameCtrl),
                    const SizedBox(height: 14),
                    AppTextField(
                        label: 'Email',
                        hint: 'email@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                        controller: _emailCtrl),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.palette.divider),
                ),
                child: Consumer<ThemeController>(
                  builder: (_, theme, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: context.palette.bubbleIn,
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
                                  color: context.palette.textPrimary)),
                        ),
                        Switch(
                          value: theme.isDark,
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
                      side: BorderSide(color: context.palette.divider),
                      backgroundColor: context.palette.surface,
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _deleting
                      ? const Center(child: CircularProgressIndicator())
                      : TextButton(
                          onPressed: _confirmDeleteProfile,
                          child: const Text('Удалить профиль',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
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
