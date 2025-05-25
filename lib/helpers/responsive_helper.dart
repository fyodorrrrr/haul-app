import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen breakpoints
  static const double _smallScreenBreakpoint = 360;
  static const double _mediumScreenBreakpoint = 768;
  static const double _largeScreenBreakpoint = 1024;
  
  // Screen size detection
  static bool isSmallScreen(BuildContext context) => 
      MediaQuery.of(context).size.width < _smallScreenBreakpoint;
  
  static bool isMediumScreen(BuildContext context) => 
      MediaQuery.of(context).size.width >= _smallScreenBreakpoint && 
      MediaQuery.of(context).size.width < _mediumScreenBreakpoint;
  
  static bool isLargeScreen(BuildContext context) => 
      MediaQuery.of(context).size.width >= _mediumScreenBreakpoint && 
      MediaQuery.of(context).size.width < _largeScreenBreakpoint;
  
  static bool isExtraLargeScreen(BuildContext context) => 
      MediaQuery.of(context).size.width >= _largeScreenBreakpoint;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= _mediumScreenBreakpoint;
  
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < _mediumScreenBreakpoint;
  
  // Get screen width
  static double screenWidth(BuildContext context) => 
      MediaQuery.of(context).size.width;
  
  static double screenHeight(BuildContext context) => 
      MediaQuery.of(context).size.height;
  
  // Grid responsiveness
  static int getGridCount(BuildContext context) {
    if (isSmallScreen(context)) return 2;
    if (isMediumScreen(context)) return 2;
    if (isLargeScreen(context)) return 3;
    return 4; // Extra large screens
  }
  
  static double getGridAspectRatio(BuildContext context) {
    if (isSmallScreen(context)) return 0.65;
    if (isMediumScreen(context)) return 0.75;
    if (isLargeScreen(context)) return 0.85;
    return 0.9; // Extra large screens
  }
  
  // Padding and margins
  static double getHorizontalPadding(BuildContext context) {
    if (isSmallScreen(context)) return 8.0;
    if (isMediumScreen(context)) return 16.0;
    if (isLargeScreen(context)) return 24.0;
    return 32.0; // Extra large screens
  }
  
  static double getVerticalPadding(BuildContext context) {
    if (isSmallScreen(context)) return 6.0;
    if (isMediumScreen(context)) return 12.0;
    if (isLargeScreen(context)) return 18.0;
    return 24.0; // Extra large screens
  }
  
  static double getCardPadding(BuildContext context) {
    if (isSmallScreen(context)) return 4.0;
    if (isMediumScreen(context)) return 8.0;
    if (isLargeScreen(context)) return 12.0;
    return 16.0; // Extra large screens
  }
  
  static double getItemSpacing(BuildContext context) {
    if (isSmallScreen(context)) return 8.0;
    if (isMediumScreen(context)) return 12.0;
    if (isLargeScreen(context)) return 16.0;
    return 20.0; // Extra large screens
  }
  
  // Font sizes
  static double getTitleFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 18.0;
    if (isMediumScreen(context)) return 22.0;
    if (isLargeScreen(context)) return 26.0;
    return 30.0; // Extra large screens
  }
  
  static double getSubtitleFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 14.0;
    if (isMediumScreen(context)) return 16.0;
    if (isLargeScreen(context)) return 18.0;
    return 20.0; // Extra large screens
  }
  
  static double getBodyFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 12.0;
    if (isMediumScreen(context)) return 14.0;
    if (isLargeScreen(context)) return 16.0;
    return 18.0; // Extra large screens
  }
  
  static double getCaptionFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 10.0;
    if (isMediumScreen(context)) return 11.0;
    if (isLargeScreen(context)) return 12.0;
    return 13.0; // Extra large screens
  }
  
  static double getPriceFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 14.0;
    if (isMediumScreen(context)) return 16.0;
    if (isLargeScreen(context)) return 18.0;
    return 20.0; // Extra large screens
  }
  
  // Icon sizes
  static double getIconSize(BuildContext context) {
    if (isSmallScreen(context)) return 18.0;
    if (isMediumScreen(context)) return 22.0;
    if (isLargeScreen(context)) return 26.0;
    return 30.0; // Extra large screens
  }
  
  static double getSmallIconSize(BuildContext context) {
    if (isSmallScreen(context)) return 14.0;
    if (isMediumScreen(context)) return 16.0;
    if (isLargeScreen(context)) return 18.0;
    return 20.0; // Extra large screens
  }
  
  static double getLargeIconSize(BuildContext context) {
    if (isSmallScreen(context)) return 24.0;
    if (isMediumScreen(context)) return 30.0;
    if (isLargeScreen(context)) return 36.0;
    return 42.0; // Extra large screens
  }
  
  // Button sizes
  static double getButtonHeight(BuildContext context) {
    if (isSmallScreen(context)) return 40.0;
    if (isMediumScreen(context)) return 44.0;
    if (isLargeScreen(context)) return 48.0;
    return 52.0; // Extra large screens
  }
  
  static double getFloatingButtonSize(BuildContext context) {
    if (isSmallScreen(context)) return 48.0;
    if (isMediumScreen(context)) return 56.0;
    if (isLargeScreen(context)) return 64.0;
    return 72.0; // Extra large screens
  }
  
  // Border radius
  static double getBorderRadius(BuildContext context) {
    if (isSmallScreen(context)) return 8.0;
    if (isMediumScreen(context)) return 12.0;
    if (isLargeScreen(context)) return 16.0;
    return 20.0; // Extra large screens
  }
  
  static double getCardBorderRadius(BuildContext context) {
    if (isSmallScreen(context)) return 6.0;
    if (isMediumScreen(context)) return 8.0;
    if (isLargeScreen(context)) return 12.0;
    return 16.0; // Extra large screens
  }
  
  // Image sizes
  static double getImageHeight(BuildContext context) {
    if (isSmallScreen(context)) return 80.0;
    if (isMediumScreen(context)) return 110.0;
    if (isLargeScreen(context)) return 140.0;
    return 170.0; // Extra large screens
  }
  
  static double getAvatarSize(BuildContext context) {
    if (isSmallScreen(context)) return 36.0;
    if (isMediumScreen(context)) return 44.0;
    if (isLargeScreen(context)) return 52.0;
    return 60.0; // Extra large screens
  }
  
  // AppBar height
  static double getAppBarHeight(BuildContext context) {
    if (isSmallScreen(context)) return 48.0;
    if (isMediumScreen(context)) return 56.0;
    if (isLargeScreen(context)) return 64.0;
    return 72.0; // Extra large screens
  }
  
  // Search-specific values
  static double getSearchCardHeight(BuildContext context) {
    if (isSmallScreen(context)) return 160.0;
    if (isMediumScreen(context)) return 180.0;
    if (isLargeScreen(context)) return 200.0;
    return 220.0; // Extra large screens
  }
  
  static double getSearchImageHeight(BuildContext context) {
    if (isSmallScreen(context)) return 90.0;
    if (isMediumScreen(context)) return 110.0;
    if (isLargeScreen(context)) return 130.0;
    return 150.0; // Extra large screens
  }
  
  // Explore screen specific values
  static double getExploreCardPadding(BuildContext context) {
    if (isSmallScreen(context)) return 2.0;
    if (isMediumScreen(context)) return 4.0;
    if (isLargeScreen(context)) return 8.0;
    return 12.0; // Extra large screens
  }
  
  static double getExploreBottomPadding(BuildContext context) {
    if (isSmallScreen(context)) return 60.0;
    if (isMediumScreen(context)) return 70.0;
    if (isLargeScreen(context)) return 80.0;
    return 90.0; // Extra large screens
  }
  
  static double getExploreActionButtonSize(BuildContext context) {
    if (isSmallScreen(context)) return 40.0;
    if (isMediumScreen(context)) return 44.0;
    if (isLargeScreen(context)) return 50.0;
    return 56.0; // Extra large screens
  }
  
  // Helper method to get all responsive values at once
  static Map<String, dynamic> getResponsiveValues(BuildContext context) {
    return {
      'isSmallScreen': isSmallScreen(context),
      'isMediumScreen': isMediumScreen(context),
      'isLargeScreen': isLargeScreen(context),
      'isExtraLargeScreen': isExtraLargeScreen(context),
      'isTablet': isTablet(context),
      'isMobile': isMobile(context),
      'screenWidth': screenWidth(context),
      'screenHeight': screenHeight(context),
      'gridCount': getGridCount(context),
      'gridAspectRatio': getGridAspectRatio(context),
      'horizontalPadding': getHorizontalPadding(context),
      'verticalPadding': getVerticalPadding(context),
      'cardPadding': getCardPadding(context),
      'itemSpacing': getItemSpacing(context),
      'titleFontSize': getTitleFontSize(context),
      'subtitleFontSize': getSubtitleFontSize(context),
      'bodyFontSize': getBodyFontSize(context),
      'captionFontSize': getCaptionFontSize(context),
      'priceFontSize': getPriceFontSize(context),
      'iconSize': getIconSize(context),
      'smallIconSize': getSmallIconSize(context),
      'largeIconSize': getLargeIconSize(context),
      'buttonHeight': getButtonHeight(context),
      'floatingButtonSize': getFloatingButtonSize(context),
      'borderRadius': getBorderRadius(context),
      'cardBorderRadius': getCardBorderRadius(context),
      'imageHeight': getImageHeight(context),
      'avatarSize': getAvatarSize(context),
      'appBarHeight': getAppBarHeight(context),
    };
  }
}