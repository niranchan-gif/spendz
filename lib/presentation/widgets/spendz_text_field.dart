import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

/// Clean minimalist text input field for Spendz 2.0.
class SpendzTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  const SpendzTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onEditingComplete,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: SpendzColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: SpendzColors.textSecondary(context).withAlpha(160),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          color: SpendzColors.textSecondary(context),
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: SpendzColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpendzSpacing.lg,
          vertical: SpendzSpacing.md,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? SpendzColors.borderDark : SpendzColors.borderLight,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
          borderSide: BorderSide(
            color: SpendzColors.primaryAccent(context),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
          borderSide: const BorderSide(color: SpendzColors.expense, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusMd),
          borderSide: const BorderSide(color: SpendzColors.expense, width: 1.5),
        ),
      ),
    );
  }
}
