import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandLogoWidget extends StatelessWidget {
  final String brandName;
  final double size;
  final bool showText;
  final bool circular;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const BrandLogoWidget({
    Key? key,
    required this.brandName,
    this.size = 40,
    this.showText = false,
    this.circular = false,
    this.backgroundColor,
    this.padding,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = Container(
      width: size,
      height: size,
      padding: padding ?? EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.15),
        border: showBorder 
            ? Border.all(
                color: borderColor ?? Colors.grey[300]!,
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _buildBrandInitial(),
    );

    if (showText) {
      return Container(
        width: size * 1.2, // ✅ Fixed width to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            logoWidget,
            SizedBox(height: size * 0.15), // ✅ Reduced spacing
            Flexible( // ✅ Use Flexible instead of fixed SizedBox
              child: Text(
                brandName,
                style: GoogleFonts.poppins(
                  fontSize: _getOptimalFontSize(brandName, size), // ✅ Dynamic font size
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                  height: 1.1, // ✅ Reduced line height
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: logoWidget,
      );
    }

    return logoWidget;
  }

  Widget _buildBrandInitial() {
    final brandColor = _getBrandColor(brandName);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandColor.withOpacity(0.8),
            brandColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          _getBrandInitials(brandName), // ✅ Better initial handling
          style: GoogleFonts.poppins(
            fontSize: size * 0.3, // ✅ Reduced size to fit better
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ✅ Get optimal font size based on brand name length
  double _getOptimalFontSize(String text, double baseSize) {
    if (text.length <= 6) {
      return baseSize * 0.18; // Larger font for short names
    } else if (text.length <= 10) {
      return baseSize * 0.15; // Medium font
    } else if (text.length <= 15) {
      return baseSize * 0.13; // Smaller font for longer names
    } else {
      return baseSize * 0.11; // Very small font for very long names
    }
  }

  // ✅ Better initial generation for brands
  String _getBrandInitials(String brandName) {
    if (brandName.isEmpty) return '?';
    
    final words = brandName.split(' ');
    if (words.length == 1) {
      // Single word: take first character
      return brandName[0].toUpperCase();
    } else if (words.length == 2) {
      // Two words: take first character of each
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      // More than two words: take first two initials
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
  }

  Color _getBrandColor(String brandName) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lime,
      Colors.deepPurple,
      Colors.brown,
    ];
    
    if (brandName.isEmpty) return Colors.grey;
    
    final hash = brandName.toLowerCase().codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }
}