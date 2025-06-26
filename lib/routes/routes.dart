import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/teams_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/group_leaderboard_screen.dart';
import '../screens/matches_screen.dart';
import '../screens/match_details_screen.dart';
import '../screens/global_matches_screen.dart';
import '../screens/inter_group_matches_screen.dart';
import '../screens/inter_group_matches_list_screen.dart';
import '../screens/inter_group_match_details_screen.dart';
import '../widgets/auth_wrapper.dart';
import '../models/group.dart';
import '../models/match.dart';

/// Class to manage all routes in the application
class AppRoutes {
  // Route names
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String groups = '/groups';
  static const String teams = '/teams';
  static const String leaderboard = '/leaderboard';
  static const String groupLeaderboard = '/group-leaderboard';
  static const String matches = '/matches';
  static const String matchDetails = '/match-details';
  static const String globalMatches = '/global-matches';
  static const String interGroupMatches = '/inter-group-matches';
  static const String interGroupMatchesList = '/inter-group-matches-list';
  static const String interGroupMatchDetails = '/inter-group-match-details';

  /// Generate routes for the application
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const AuthWrapper(),
      // login route removed to prevent direct navigation
      // login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      groups: (context) => const GroupsScreen(),
      leaderboard: (context) => const LeaderboardScreen(),
      matchDetails: (context) => const MatchDetailsScreen(),
      globalMatches: (context) => const GlobalMatchesScreen(),
      interGroupMatches: (context) => const InterGroupMatchesScreen(),
      interGroupMatchesList: (context) => const InterGroupMatchesListScreen(),
      // Note: Teams, Matches, and GroupLeaderboard screens require parameters,
      // so they are not included here. Use the navigation methods below.
    };
  }

  /// Navigate to the teams screen with the required parameters
  static void navigateToTeams(BuildContext context, int groupId, String groupName) {
    // Create a Group object with the required parameters
    final group = Group(
      id: groupId,
      name: groupName,
      description: '', // Default empty description
      createdAt: DateTime.now(), // Default to current time
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamsScreen(group: group),
      ),
    );
  }

  /// Navigate to the group leaderboard screen with the required parameters
  static void navigateToGroupLeaderboard(BuildContext context, int groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupLeaderboardScreen(groupId: groupId, groupName: groupName),
      ),
    );
  }
  
  /// Navigate to the matches screen with the required parameters
  static void navigateToMatches(BuildContext context, int groupId, String groupName) {
    // Create a Group object with the required parameters
    final group = Group(
      id: groupId,
      name: groupName,
      description: '', // Default empty description
      createdAt: DateTime.now(), // Default to current time
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchesScreen(group: group),
      ),
    );
  }
  
  /// Navigate to the inter-group match details screen with the required match
  static void navigateToInterGroupMatchDetails(BuildContext context, Match match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterGroupMatchDetailsScreen(match: match),
      ),
    );
  }
}