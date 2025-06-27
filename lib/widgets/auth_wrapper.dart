import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoreboard App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Scoreboard App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('View Global Match History'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Navigate to global matches screen as guest
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GlobalMatchesScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.leaderboard),
              label: const Text('View Leaderboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Navigate to leaderboard screen as guest
                Navigator.pushNamed(context, AppRoutes.leaderboard);
              },
            ),
            // const SizedBox(height: 16),
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.login),
            //   label: const Text('Sign In'),
            //   style: ElevatedButton.styleFrom(
            //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            //   ),
            //   onPressed: () {
            //     // Navigate to login screen
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const LoginScreen()),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}