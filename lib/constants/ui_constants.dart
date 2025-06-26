import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// UI Constants for standardized padding and spacing across the app
/// This helps ensure consistent UI on all platforms, especially web
class AppPadding {
  // Standard edge insets for screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  
  // Responsive screen padding with different values for x and y axis
  static const EdgeInsets screenPaddingResponsive = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );
  
  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  
  // List item padding
  static EdgeInsets getListItemPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (kIsWeb) {
      // More padding for web
      return const EdgeInsets.symmetric(
        horizontal: 40.0, // Increased from 32px
        vertical: 12.0,   // Increased from 8px
      );
    } else if (width < AppSizing.mobileBreakpoint) {
      // Mobile padding
      return const EdgeInsets.symmetric(
        horizontal: 8.0, // Reduced from 16px to fix overflow
        vertical: 8.0,   // Reduced from 10px
      );
    } else {
      // Tablet and larger devices
      return const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 12.0,
      );
    }
  }
  
  // Legacy list item padding (for backward compatibility)
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  
  // Form field padding
  static const EdgeInsets formFieldPadding = EdgeInsets.symmetric(
    vertical: 8.0,
  );
  
  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  
  // Small spacing between elements
  static const double smallSpacing = 8.0;
  
  // Medium spacing between elements
  static const double mediumSpacing = 16.0;
  
  // Large spacing between elements
  static const double largeSpacing = 24.0;
}

/// Responsive sizing constants
class AppSizing {
  // Maximum width for content on large screens
  static const double maxContentWidth = 1200.0;
  
  // Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  
  // Helper method to get responsive horizontal padding based on screen width
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }
  
  // Helper method to get content constraints based on screen width
  static BoxConstraints getContentConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: maxContentWidth,
      minWidth: 0,
    );
  }
}