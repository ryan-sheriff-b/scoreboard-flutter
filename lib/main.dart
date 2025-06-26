import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scoreboard/services/firebase_service.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import for web functionality
import 'web_url_strategy.dart';

import 'providers/group_provider.dart';
import 'providers/team_provider.dart';
import 'providers/member_provider.dart';
import 'providers/score_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/match_provider.dart';
import 'providers/global_match_provider.dart';
import 'routes/routes.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'constants/ui_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Auth with persistence
  final firebaseService = FirebaseService();
  await firebaseService.initializeAuth();
  
  // Initialize web URL strategy if on web platform
  if (kIsWeb) {
    WebUrlStrategy.initialize();
  }
  
  runApp(const MyApp());
}

// Function to handle route generation based on URL path
Route<dynamic> handleRouteGeneration(RouteSettings settings) {
  // Get the route name from settings
  final String? name = settings.name;
  
  // Handle login route specially - redirect to LoginScreen
  if (name == AppRoutes.login) {
    return MaterialPageRoute(builder: (context) => const LoginScreen());
  }
  
  // For all other routes, use the routes defined in AppRoutes
  final routes = AppRoutes.getRoutes();
  final WidgetBuilder? builder = routes[name ?? ''];
  
  if (builder != null) {
    return MaterialPageRoute(builder: builder);
  }
  
  // If route not found, go to home
  return MaterialPageRoute(builder: (context) => const AuthWrapper());
}

// Class to observe URL changes and handle navigation
class UrlObserver extends NavigatorObserver {
  final GlobalKey<NavigatorState> navigatorKey;

  UrlObserver(this.navigatorKey) {
    // Initialize web URL strategy
    WebUrlStrategy.initialize();
    
    // Handle initial URL if on web
    if (kIsWeb) {
      _handleInitialUrl();
    }
  }

  void _handleInitialUrl() {
    if (!kIsWeb) return;
    
    // Get the current URL path
    final String path = WebUrlStrategy.getCurrentPath();
    
    // If we're at the root, don't do anything special
    if (path == '/' || path.isEmpty) return;
    
    // Navigate to the path using our route handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushReplacement(
        handleRouteGeneration(RouteSettings(name: path))
      );
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Only update browser URL when running on the web
    if (kIsWeb) {
      // Update browser URL when routes change within the app
      if (route.settings.name != null && route.settings.name != '/') {
        WebUrlStrategy.updateBrowserUrl(route.settings.name);
      }
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a navigator key to access the navigator from the URL observer
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    
    // Create the URL observer
    final urlObserver = UrlObserver(navigatorKey);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => ScoreProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => GlobalMatchProvider()),
      ],
      child: MaterialApp(
        title: 'Scoreboard App by Rahman Basha',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [urlObserver],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          // Add standardized padding through input decorations
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: AppPadding.formFieldPadding,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blue, width: 2.0),
            ),
          ),
          // Add standardized padding through card theme
          cardTheme: CardTheme(
            elevation: 2.0,
            margin: AppPadding.listItemPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          // Add standardized padding through button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: AppPadding.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        initialRoute: AppRoutes.home,
        // Use onGenerateRoute for all routes to handle web URLs properly
        onGenerateRoute: (settings) => handleRouteGeneration(settings),
        // Use routeInformationParser to handle URL-based navigation
        onGenerateInitialRoutes: (String initialRoute) {
          // Parse the initial route and navigate accordingly
          return [handleRouteGeneration(RouteSettings(name: initialRoute))];
        },
      ),
    );
  }
}
