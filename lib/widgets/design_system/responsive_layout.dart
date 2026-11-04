import 'package:flutter/material.dart';

/// Responsive layout utilities and breakpoint wrappers for Spendz 2.0.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 640.0,
    this.padding = EdgeInsets.zero,
  });

  /// True if current viewport is a standard or compact phone (< 600px).
  static bool isCompact(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// True if current viewport is a tablet or unfolded foldable (>= 600px).
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Safe responsive content width
  static double contentWidth(BuildContext context, {double maxWidth = 640.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > maxWidth ? maxWidth : screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
