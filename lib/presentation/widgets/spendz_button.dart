import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

enum SpendzButtonVariant { primary, secondary, ghost, tonal }

/// Matte pill action button. Brand colours are kept for small icon accents.
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
    final enabled = widget.onPressed != null && !widget.isLoading;
    final ghost = widget.variant == SpendzButtonVariant.ghost;

    final background = widget.customColor ??
        (ghost
            ? Colors.transparent
            : SpendzColors.surfaceElevated(context));
    final foreground = widget.customTextColor ??
        (ghost
            ? SpendzColors.textPrimary(context)
            : SpendzColors.textPrimary(context));

    final shadows = !enabled || ghost || _isPressed
        ? <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 34 : 12),
              blurRadius: 14,
              offset: const Offset(0, 5),
              spreadRadius: -3,
            ),
          ];

    final content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 19,
              color: widget.customTextColor ??
                  SpendzColors.primaryAccent(context),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        height: widget.height,
        width: widget.isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: enabled ? background : SpendzColors.surfaceRecessed(context),
          borderRadius: BorderRadius.circular(SpendzSpacing.radiusFull),
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
            onTap: enabled ? widget.onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpendzSpacing.xl,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
