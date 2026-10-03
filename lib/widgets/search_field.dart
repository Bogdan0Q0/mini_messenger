import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Поле поиска со значком лупы и кнопкой «очистить».
class SearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchField({
    super.key,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: palette.bubbleIn,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: palette.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(color: palette.textSecondary, fontSize: 15),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) {
              if (value.text.isEmpty) return const SizedBox(width: 12);
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                icon: Icon(Icons.close, size: 18, color: palette.textSecondary),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
