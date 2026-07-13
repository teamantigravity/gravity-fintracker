import 'package:intl/intl.dart';

class CurrencyHelper {
  static String format(
      double amount, {
        String? symbol = "\$",
        String? locale,
      }) {
    final String safeSymbol = symbol ?? "\$";
    return NumberFormat.currency(symbol: safeSymbol, locale: locale, decimalDigits: 2).format(amount);
  }
}

