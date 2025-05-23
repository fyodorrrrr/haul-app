class CurrencyFormatter {
  // Use the Unicode code point for Philippine Peso to ensure compatibility
  static const String _pesoSymbol = '\u20B1'; // Unicode for ₱
  
  /// Format amount with peso symbol
  static String format(double amount, {int decimals = 2}) {
    return '$_pesoSymbol${amount.toStringAsFixed(decimals)}';
  }
  
  /// Format amount with peso symbol (no decimals for display)
  static String formatWhole(double amount) {
    return '$_pesoSymbol${amount.toInt()}';
  }
  
  /// Format with thousands separator
  static String formatWithCommas(double amount, {int decimals = 2}) {
    final formatted = amount.toStringAsFixed(decimals);
    final parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    
    // Add commas to integer part
    String result = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = ',$result';
      }
      result = '${integerPart[i]}$result';
      count++;
    }
    
    if (decimals > 0 && decimalPart.isNotEmpty) {
      return '$_pesoSymbol$result.$decimalPart';
    }
    return '$_pesoSymbol$result';
  }
  
  /// Get just the peso symbol
  static String get symbol => _pesoSymbol;
  
  /// Parse currency string back to double
  static double parse(String currencyString) {
    final cleanString = currencyString
        .replaceAll(_pesoSymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleanString) ?? 0.0;
  }
}