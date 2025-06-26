// This file provides stub implementations for dart:html when running on non-web platforms

// Stub for window
class Window {
  // Stub for location
  final Location location = Location();
  
  // Stub for history
  final History history = History();
  
  // Stub for onPopState
  Stream<dynamic> get onPopState => const Stream.empty();
}

// Stub for Location
class Location {
  // Stub for pathname
  String get pathname => '/';
}

// Stub for History
class History {
  // Stub for pushState
  void pushState(dynamic state, String title, [String? url]) {}
}

// Stub for window
final Window window = Window();