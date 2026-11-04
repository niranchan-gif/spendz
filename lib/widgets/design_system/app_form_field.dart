import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// Standardized Form Field with clear labels, floating focus, and validation states.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            enabled: enabled,
            textCapitalization: textCapitalization,
            style: AppTextStyles.getBodyMedium(context),
            decoration: InputDecoration(
              hintText: hint ?? hintText,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.getTextHint(context), size: 20)
                  : null,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.getSurfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: BorderSide(color: AppColors.getBorder(context), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: BorderSide(color: AppColors.getBorder(context), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: BorderSide(color: AppColors.getPrimary(context), width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: BorderSide(color: AppColors.getError(context), width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
