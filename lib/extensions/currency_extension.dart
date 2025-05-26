import '../utils/currency_formatter.dart';

extension CurrencyExtension on num {
  /// Format number as Philippine Peso currency
  String toPeso({int decimals = 2}) {
    return CurrencyFormatter.format(this.toDouble(), decimals: decimals);
  }
  
  /// Format number as Philippine Peso with commas
  String toPesoWithCommas({int decimals = 2}) {
    return CurrencyFormatter.formatWithCommas(this.toDouble(), decimals: decimals);
  }
  
  /// Format as whole peso (no decimals)
  String toWholePeso() {
    return CurrencyFormatter.formatWhole(this.toDouble());
  }
}