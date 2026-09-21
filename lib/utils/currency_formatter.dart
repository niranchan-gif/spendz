import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }
}
