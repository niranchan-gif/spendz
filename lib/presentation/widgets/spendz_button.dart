import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

enum SpendzButtonVariant { primary, secondary, ghost, tonal }

/// Spendz Funky Claymorphism Pill Action Button.
///
/// Inflated 3D tactile button with dual chromatic drop shadow, top-left white sheen,
/// and smooth scale press animation.
class SpendzButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SpendzButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final Color? customColor;
  final Color? customTextColor;

  const SpendzButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = SpendzButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50,
    this.customColor,
    this.customTextColor,
  });

  const SpendzButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.primary;

  const SpendzButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.secondary;

  const SpendzButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.ghost;

  const SpendzButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50,
    this.customColor,
    this.customTextColor,
  }) : variant = SpendzButtonVariant.tonal;

  @override
  State<SpendzButton> createState() => _SpendzButtonState();
}

class _SpendzButtonState extends State<SpendzButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = SpendzColors.isDark(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bgColor;
    Color fgColor;
    Color shadowTint;

    switch (widget.variant) {
      case SpendzButtonVariant.primary:
        bgColor = widget.customColor ?? SpendzColors.tangerine;
        fgColor = widget.customTextColor ?? Colors.white;
        shadowTint = SpendzColors.tangerine;
        break;

      case SpendzButtonVariant.secondary:
        bgColor = widget.customColor ?? SpendzColors.sunshineYellow;
        fgColor = widget.customTextColor ?? const Color(0xFF735500);
        shadowTint = SpendzColors.sunshineDeep;
        break;

      case SpendzButtonVariant.tonal:
        bgColor = widget.customColor ?? SpendzColors.periwinkle;
        fgColor = widget.customTextColor ?? Colors.white;
        shadowTint = SpendzColors.periwinkleDeep;
        break;

      case SpendzButtonVariant.ghost:
        bgColor = widget.customColor ?? Colors.transparent;
        fgColor = widget.customTextColor ?? SpendzColors.textPrimary(context);
        shadowTint = Colors.transparent;
        break;
    }

    if (!isEnabled && widget.variant != SpendzButtonVariant.ghost) {
      bgColor = isDark ? const Color(0xFF233042) : const Color(0xFFE2E8F0);
      fgColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
      shadowTint = Colors.transparent;
    }

    final List<BoxShadow> shadows = [];
    if (isEnabled && widget.variant != SpendzButtonVariant.ghost) {
      if (!_isPressed) {
        shadows.addAll([
          BoxShadow(
            color: shadowTint.withAlpha(isDark ? 70 : 85),
            blurRadius: 18,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: shadowTint.withAlpha(isDark ? 40 : 50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ]);
      } else {
        shadows.add(
          BoxShadow(
            color: shadowTint.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        );
      }
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 19, color: fgColor),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Container(
        height: widget.height,
        width: widget.isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            SpendzSpacing.radiusFull,
          ), // rounded-pill (9999px)
          border: Border.all(
            color: widget.variant == SpendzButtonVariant.ghost
                ? (isDark ? Colors.white24 : const Color(0xFFCBD5E1))
                : Colors.white.withAlpha(isEnabled ? 160 : 40),
            width: 1.2,
          ),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
          child: InkWell(
            borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
            onHighlightChanged: (pressed) {
              setState(() => _isPressed = pressed);
            },
            onTap: isEnabled ? widget.onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpendzSpacing.xl),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
