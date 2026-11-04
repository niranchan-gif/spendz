import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';
import '../glass/glass_input.dart';

/// Standardized Form Field built on the Spendz 2.0 GlassInput primitive.
class AppFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final TextCapitalization textCapitalization;

  const AppFormField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassInput(
        controller: controller,
        label: label,
        hint: hintText ?? hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        maxLines: maxLines,
        enabled: enabled,
      ),
    );
  }
}
