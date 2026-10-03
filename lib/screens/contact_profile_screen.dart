import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/storage/prefs_storage.dart';
import '../theme/app_theme.dart';
import '../utils/navigation.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/nav_header.dart';
import '../widgets/rename_dialog.dart';
import 'photo_viewer_screen.dart';

/// Профиль контакта: имя, переименование, удаление и фото,
/// которые вы отправляли этому контакту.
class ContactProfileScreen extends StatefulWidget {
  final Contact contact;
  const ContactProfileScreen({super.key, required this.contact});

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  final _repo = ContactsRepository.shared;
  final _storage = PrefsStorage();
  late Contact _contact = widget.contact;
  List<String> _photos = [];
  bool _loadingMedia = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  /// Фото из переписки: только отправленные вами, новые сверху.
  Future<void> _loadMedia() async {
    final messages = await _storage.loadMessages(_contact.id);
    final photos = <String>[];
    for (final m in messages.reversed) {
      final path = m.imagePath;
      if (m.outgoing && path != null && path.isNotEmpty) {
        if (await File(path).exists()) photos.add(path);
      }
    }
    if (!mounted) return;
    setState(() {
      _photos = photos;
      _loadingMedia = false;
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _rename() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => RenameDialog(initialName: _contact.name),
    );
    if (result == null || result.isEmpty || result == _contact.name) return;
    try {
      await _repo.rename(_contact.id, result);
    } catch (_) {
      if (mounted) _snack('Не удалось сохранить имя', error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _contact = _contact.withName(result));
    _snack('Контакт переименован');
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить контакт?'),
        content: const Text('Контакт, переписка и фото будут удалены.'),
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
    if (ok != true) return;
    try {
      await _repo.delete(_contact.id);
    } catch (_) {
      if (mounted) _snack('Не удалось удалить контакт', error: true);
      return;
    }
    if (!mounted) return;
    // Диалог, из которого открыт профиль, увидит, что контакта больше нет,
    // и закроется сам.
    Navigator.pop(context);
  }

  void _openPhoto(int index) {
    pushScreen<void>(
      context,
      PhotoViewerScreen(paths: _photos, initialIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              NavHeader(
                title: 'Профиль контакта',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              CustomAvatar(
                initials: _contact.initials,
                color: _contact.color,
                size: 100,
              ),
              const SizedBox(height: 14),
              Text(_contact.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary)),
              const SizedBox(height: 2),
              Text(_contact.username,
                  style: TextStyle(fontSize: 14, color: palette.textSecondary)),
              const SizedBox(height: 28),
              // Material вместо Container с цветом: иначе ListTile не может
              // нарисовать подсветку нажатия под непрозрачным фоном.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: palette.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: palette.divider),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        title: Text('Переименовать',
                            style: TextStyle(color: palette.textPrimary)),
                        onTap: _rename,
                      ),
                      Divider(
                          height: 0.5, thickness: 0.5, color: palette.divider),
                      ListTile(
                        leading: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                        title: const Text('Удалить контакт',
                            style: TextStyle(color: AppColors.error)),
                        onTap: _confirmDelete,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _photos.isEmpty ? 'МЕДИА' : 'МЕДИА · ${_photos.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildMedia(palette),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(AppPalette palette) {
    if (_loadingMedia) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      );
    }
    if (_photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Text('Вы пока не отправляли фото этому контакту',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 14)),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: _photos.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _openPhoto(i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_photos[i]),
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (_, _, _) => Container(
              color: palette.divider,
              child: Icon(Icons.broken_image, color: palette.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
