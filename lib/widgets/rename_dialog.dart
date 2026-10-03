import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Диалог переименования контакта. Закрывается с новым именем
/// (или `null`, если нажали «Отмена»). Контроллер живёт внутри диалога
/// и освобождается вместе с ним.
class RenameDialog extends StatefulWidget {
  final String initialName;
  const RenameDialog({super.key, required this.initialName});

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _ctrl.text.trim());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      title: const Text('Переименовать'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: TextStyle(color: palette.textPrimary),
        decoration: const InputDecoration(hintText: 'Новое имя'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена', style: TextStyle(color: palette.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Сохранить',
              style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
