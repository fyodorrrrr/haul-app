import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandLogoWidget extends StatelessWidget {
  final String brandName;
  final double size;
  final bool showText;
  final bool circular;
  final bool showBorder;
  final VoidCallback? onTap; // ✅ Make sure this exists
  final Color? backgroundColor;

  const BrandLogoWidget({
    Key? key,
    required this.brandName,
    this.size = 50,
    this.showText = false,
    this.circular = false,
    this.showBorder = false,
    this.onTap, // ✅ Make sure this exists
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // ✅ Make sure this wraps everything
      onTap: () {
        print('🔥 BrandLogoWidget tapped: $brandName'); // ✅ Add debug print
        if (onTap != null) {
          onTap!();
        } else {
          print('❌ onTap is null for $brandName');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Your brand logo container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: circular ? BoxShape.circle : BoxShape.rectangle,
              border: showBorder ? Border.all(color: Colors.grey[300]!) : null,
              color: backgroundColor ?? Colors.white,
            ),
            child: Center(
              child: _buildBrandLogo(),
            ),
          ),
          
          // Brand name text
          if (showText) ...[
            SizedBox(height: 4),
            Text(
              brandName,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrandLogo() {
    // Your existing brand logo logic
    return Text(
      brandName[0].toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: size * 0.4,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}