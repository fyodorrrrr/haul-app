import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnackBarHelper {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration? duration,
  }) {
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError 
                    ? theme.colorScheme.onError.withOpacity(0.2)
                    : theme.colorScheme.onPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError 
                    ? theme.colorScheme.onError 
                    : theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: isError 
                      ? theme.colorScheme.onError 
                      : theme.colorScheme.onPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isError 
                    ? theme.colorScheme.onError.withOpacity(0.2)
                    : theme.colorScheme.onPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isError 
                      ? theme.colorScheme.onError 
                      : theme.colorScheme.onPrimary,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          ],
        ),
        backgroundColor: isError 
            ? theme.colorScheme.error 
            : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration ?? const Duration(seconds: 2),
        dismissDirection: DismissDirection.horizontal,
        animation: CurvedAnimation(
          parent: const AlwaysStoppedAnimation(1),
          curve: Curves.easeOutCirc,
        ),
      ),
    );
  }
}