import 'package:flutter/material.dart';

/// Extension on State to provide safe setState functionality
extension SafeSetState on State {
  /// Safely calls setState only if the widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
