import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? right;

  const NavHeader({
    super.key,
    required this.title,
    this.onBack,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: onBack != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.primary, size: 28),
                    onPressed: onBack,
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: Align(
              alignment: Alignment.centerRight,
              child: right ?? const SizedBox(width: 40),
            ),
          ),
        ],
      ),
    );
  }
}
