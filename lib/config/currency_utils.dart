import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  /// Formats a number to Indonesian Rupiah representation: e.g. Rp. 30.000
  static String format(num? amount) {
    if (amount == null) return 'Rp. 0';
    return _formatter.format(amount);
  }
}
