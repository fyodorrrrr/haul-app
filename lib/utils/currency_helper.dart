class CurrencyHelper {
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
  static const String currencyName = 'Philippine Peso';
  
  /// Format a double value to Philippine Peso currency string
  static String formatAmount(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
  
  /// Format with thousand separators for large amounts
  static String formatAmountWithCommas(double amount) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formatted = amount.toStringAsFixed(2);
    formatted = formatted.replaceAllMapped(formatter, (match) => '${match[1]},');
    return '$currencySymbol$formatted';
  }
  
  /// Parse a currency string back to double
  static double parseAmount(String currencyString) {
    final cleanString = currencyString
        .replaceAll(currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleanString) ?? 0.0;
  }
  
  /// Check if string is a valid currency format
  static bool isValidCurrencyFormat(String value) {
    final regex = RegExp(r'^\₱?[\d,]+\.?\d{0,2}$');
    return regex.hasMatch(value.trim());
  }
}