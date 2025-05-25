import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/brand_logo_service.dart';

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
    final logoPath = BrandLogoService.getBrandLogo(brandName);
    final hasLogo = BrandLogoService.hasBrandLogo(brandName);

    Widget logoWidget = Container(
      width: size,
      height: size,
      padding: padding ?? EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: backgroundColor ?? (hasLogo ? Colors.white : Colors.grey[100]),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.15),
        border: showBorder 
            ? Border.all(
                color: borderColor ?? Colors.grey[300]!,
                width: 1,
              )
            : null,
        boxShadow: hasLogo ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ] : null,
      ),
      child: hasLogo
          ? Image.asset(
              logoPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackLogo();
              },
            )
          : _buildFallbackLogo(),
    );

    if (showText) {
      logoWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoWidget,
          SizedBox(height: size * 0.2),
          SizedBox(
            width: size * 1.5,
            child: Text(
              brandName,
              style: GoogleFonts.poppins(
                fontSize: size * 0.25,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  Widget _buildFallbackLogo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circular ? null : BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          brandName.isNotEmpty ? brandName[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}