import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController controller;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    required this.controller,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool show = false;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Text(widget.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        if (widget.label.isNotEmpty) const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: isPassword && !show,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      show ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => show = !show),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
