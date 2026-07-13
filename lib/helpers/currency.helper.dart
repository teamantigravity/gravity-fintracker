import 'package:intl/intl.dart';

class CurrencyHelper {
  static String format(
      double amount, {
        String? symbol = "₹",
        String? name = "INR",
        String? locale = "en_IN",
      }) {
    final String safeSymbol = symbol ?? "₹";
    return NumberFormat('$safeSymbol##,##,##,###.####', locale).format(amount);
  }
}

