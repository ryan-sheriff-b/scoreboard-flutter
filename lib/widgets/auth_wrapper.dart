import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scoreboard/constants/app_images.dart';
import 'package:scoreboard/widgets/appbar_icon.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/global_matches_screen.dart';
import '../routes/routes.dart';

/// A wrapper widget that handles authentication state changes and routes users accordingly.
/// This widget listens to the authentication state and redirects users to the appropriate screen.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh admin status when the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        await authProvider.refreshAdminStatus();
        authProvider.debugAdminStatus();
      }
    });

    // Listen to auth changes
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading indicator while authentication state is being determined
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (authProvider.isAuthenticated) {
          // User is logged in, navigate to groups screen
          return const GroupsScreen();
        } else {
          // User is not logged in, show guest mode options
          return _buildGuestModeScreen(context);
        }
      },
    );
  }

  // Build the guest mode screen with options to view global matches, leaderboard, or login
  Widget _buildGuestModeScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBarIcon(size: screenWidth < 600 ? 80 : 150),
            const Spacer(),
            Center(
              child: Text('ScoreHub GameOn!',
                  style:
                      TextStyle(fontSize: screenWidth < 600.0 ? 16.0 : 30.0)),
            ),
            const Spacer(),
            SizedBox(
              height: screenWidth < 600 ? 80 : 150,
              width: screenWidth < 600 ? 80 : 150,
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppImages.logo, width: 300),
                const SizedBox(height: 50),
                const Text(
                  'Welcome to the Scoreboard App',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View Global Match History'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GlobalMatchesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('View Leaderboard'),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.leaderboard);
                  },
                ),
              ],
            ),
          ),

          // Bottom-right corner text
          const Positioned(
            bottom: 16,
            right: 16,
            child: Text(
              'by flutter \u{1F499}',
              style: TextStyle(fontFamily: 'sans-serif'),
            ),
          ),
        ],
      ),
    );
  }
}
