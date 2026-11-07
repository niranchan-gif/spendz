import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:keybz/widgets/app_keyboard/app_keyboard.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Unified Glass Input Field for Spendz 2.0 Fintech UI.
///
/// Combines selective frosted backdrop styling with accessible form validation,
/// clear focus indicators, and high-contrast typography.
class GlassInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool disableBlur;
  final bool autofocus;
  final FocusNode? focusNode;
  final double borderRadius;

  const GlassInput({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.enabled = true,
    this.disableBlur = false,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final emerald = AppColors.getEmeraldAccent(context);
    final textPrimary = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);

    Widget field = AppTextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 13.0,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: emerald,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: textSecondary.withAlpha(120),
          fontSize: 14.0,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF14231B).withAlpha(190)
            : const Color(0xFFFFFFFF).withAlpha(205),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 14.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: AppColors.getGlassBorder(context),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: emerald, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: AppColors.getError(context),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: AppColors.getError(context),
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: AppColors.getBorder(context).withAlpha(60),
            width: 0.8,
          ),
        ),
      ),
    );

    if (!disableBlur) {
      field = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: field,
        ),
      );
    }

    return field;
  }
}
