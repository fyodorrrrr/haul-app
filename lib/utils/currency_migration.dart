import 'currency_formatter.dart';

class CurrencyMigration {
  /// Replace old dollar formatting with peso formatting
  static String migrateCurrency(String text) {
    // Replace common dollar patterns using replaceAllMapped
    text = text.replaceAllMapped(RegExp(r'\$(\d+\.?\d*)'), (match) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      return CurrencyFormatter.format(amount);
    });
    
    return text;
  }
  
  /// Format any numeric value as peso
  static String formatAsPeso(dynamic value) {
    if (value is num) {
      return CurrencyFormatter.format(value.toDouble());
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return CurrencyFormatter.format(parsed);
      }
    }
    return CurrencyFormatter.format(0.0);
  }
  
  /// Enhanced migration with more patterns
  static String migrateAllCurrencyPatterns(String text) {
    // Replace $123.45 patterns
    text = text.replaceAllMapped(RegExp(r'\$(\d+\.?\d*)'), (match) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      return CurrencyFormatter.format(amount);
    });
    
    // Replace dollar symbols followed by numbers
    text = text.replaceAllMapped(RegExp(r'\$\s*(\d+(?:\.\d{2})?)'), (match) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      return CurrencyFormatter.format(amount);
    });
    
    // Replace "USD" patterns
    text = text.replaceAllMapped(RegExp(r'(\d+\.?\d*)\s*USD'), (match) {
      final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      return CurrencyFormatter.format(amount);
    });
    
    return text;
  }
  
  /// Migrate currency in a list of strings
  static List<String> migrateCurrencyList(List<String> texts) {
    return texts.map((text) => migrateCurrency(text)).toList();
  }
  
  /// Migrate currency in a map of values
  static Map<String, dynamic> migrateCurrencyMap(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    
    for (final entry in data.entries) {
      if (entry.value is String) {
        result[entry.key] = migrateCurrency(entry.value);
      } else if (entry.value is List) {
        result[entry.key] = entry.value.map((item) {
          if (item is String) {
            return migrateCurrency(item);
          }
          return item;
        }).toList();
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] = migrateCurrencyMap(entry.value);
      } else {
        result[entry.key] = entry.value;
      }
    }
    
    return result;
  }
}