import 'package:flutter/material.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

/// Clean, borderless matte input field for Spendz.
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
    final radius = BorderRadius.circular(SpendzSpacing.radiusMd);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    );

    return AppTextFormField(
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
        fillColor: SpendzColors.surfaceElevated(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpendzSpacing.lg,
          vertical: SpendzSpacing.md,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        errorBorder: border,
        focusedErrorBorder: border,
      ),
    );
  }
}
