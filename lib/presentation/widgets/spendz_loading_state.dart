import 'package:flutter/material.dart';
import '../../app/theme/spendz_colors.dart';
import '../../app/theme/spendz_spacing.dart';

/// Clean minimalist loading state.
class SpendzLoadingState extends StatelessWidget {
  final String? message;

  const SpendzLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpendzSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  SpendzColors.primaryAccent(context),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: SpendzSpacing.lg),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 13,
                  color: SpendzColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
