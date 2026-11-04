import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';
import '../../app/theme/spendz_typography.dart';

/// Minimalist editorial app bar for Spendz 2.0.
class SpendzAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;

  const SpendzAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBack,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showBackButton) {
      effectiveLeading = Padding(
        padding: const EdgeInsets.only(left: SpendzSpacing.sm),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SpendzColors.surface(context),
              border: Border.all(color: SpendzColors.border(context), width: 1),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: SpendzColors.textPrimary(context),
              ),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: SpendzColors.background(context),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: effectiveLeading,
      leadingWidth: showBackButton ? 48 : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: SpendzTypography.headingMedium(context)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle!, style: SpendzTypography.caption(context)),
          ],
        ],
      ),
      actions: actions != null
          ? [...actions!, const SizedBox(width: SpendzSpacing.md)]
          : null,
      bottom: bottom,
    );
  }
}
