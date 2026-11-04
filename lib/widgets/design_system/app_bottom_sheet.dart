import 'package:flutter/material.dart';
import '../glass/glass_bottom_sheet.dart';

/// Standardized Modal Bottom Sheet shell built on Spendz 2.0 GlassBottomSheet.
class AppBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? trailing;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.trailing,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
    Widget? trailing,
    bool isScrollControlled = true,
  }) {
    return GlassBottomSheet.show<T>(
      context: context,
      title: title,
      trailing: trailing,
      isScrollControlled: isScrollControlled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ),
          ],
          Flexible(child: child),
          if (actions != null && actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final act = actions;
    return GlassBottomSheet(
      title: title,
      trailing: trailing,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ),
          ],
          Flexible(child: child),
          if (act != null && act.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: act),
          ],
        ],
      ),
    );
  }
}
