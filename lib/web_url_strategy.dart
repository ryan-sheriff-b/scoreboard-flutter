import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Web-specific imports with conditional compilation
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Class to handle URL-based navigation for web platforms
class WebUrlStrategy {
  /// Initialize web-specific URL handling
  static void initialize() {
    if (!kIsWeb) return;
    
    // Use history API for cleaner URLs if available
    _useHistoryApi();
  }
  
  /// Configure the web app to use the HTML History API for navigation
  static void _useHistoryApi() {
    if (!kIsWeb) return;
    
    // This is a workaround to use the History API
    // It removes the hash from the URL
    try {
      js.context.callMethod('eval', [
        'window.history.pushState({}, "", window.location.pathname + window.location.search);'
      ]);
    } catch (e) {
      // Ignore errors if JS interop fails
      debugPrint('Error setting up history API: $e');
    }
  }
  
  /// Update the browser URL without triggering navigation
  static void updateBrowserUrl(String? url) {
    if (!kIsWeb || url == null) return;
    
    try {
      js.context.callMethod('eval', [
        'window.history.pushState({}, "", "$url");'
      ]);
    } catch (e) {
      // Ignore errors if JS interop fails
      debugPrint('Error updating browser URL: $e');
    }
  }
  
  /// Get the current URL path from the browser
  static String getCurrentPath() {
    if (!kIsWeb) return '/';
    
    try {
      final String path = js.context['location']['pathname'].toString();
      return path.isEmpty ? '/' : path;
    } catch (e) {
      // Return default path if JS interop fails
      return '/';
    }
  }
}