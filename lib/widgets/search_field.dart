import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchField extends StatelessWidget {
  final String hint;
  const SearchField({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bubbleIn,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
