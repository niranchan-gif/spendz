import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';

/// Translucent Glass Bottom Sheet Container for Spendz 2.0.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final double maxHeightFactor;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.maxHeightFactor = 0.88,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) =>
          GlassBottomSheet(title: title, trailing: trailing, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF14231B).withAlpha(235)
                  : const Color(0xFFFFFFFF).withAlpha(240),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(40)
                      : Colors.white.withAlpha(240),
                  width: 1.2,
                ),
                left: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.white.withAlpha(180),
                  width: 0.8,
                ),
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.white.withAlpha(180),
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 25),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: AppColors.getTextSecondary(
                            context,
                          ).withAlpha(70),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ] else ...[
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
