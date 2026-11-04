import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/spendz_colors.dart';

enum SpendzAmountVariant { regular, income, expense, muted }

/// High-contrast currency & amount text widget for Spendz 2.0.
class SpendzAmountText extends StatelessWidget {
  final double amount;
  final SpendzAmountVariant variant;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isVisible;
  final bool showSign;
  final String symbol;

  const SpendzAmountText({
    super.key,
    required this.amount,
    this.variant = SpendzAmountVariant.regular,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w700,
    this.isVisible = true,
    this.showSign = false,
    this.symbol = '₹',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return Text(
        '$symbol••••••',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 2.0,
          color: _getColor(context),
        ),
      );
    }

    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    );

    String formatted = formatter.format(amount.abs());
    String prefix = '';
    if (showSign) {
      if (variant == SpendzAmountVariant.income || amount > 0) {
        prefix = '+';
      } else if (variant == SpendzAmountVariant.expense || amount < 0) {
        prefix = '-';
      }
    }

    return Text(
      '$prefix$formatted',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.5,
        color: _getColor(context),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Color _getColor(BuildContext context) {
    switch (variant) {
      case SpendzAmountVariant.income:
        return SpendzColors.income;
      case SpendzAmountVariant.expense:
        return SpendzColors.expense;
      case SpendzAmountVariant.muted:
        return SpendzColors.textSecondary(context);
      case SpendzAmountVariant.regular:
        return SpendzColors.textPrimary(context);
    }
  }
}
