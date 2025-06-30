import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scoreboard/routes/routes.dart';
import 'package:scoreboard/screens/groups_screen.dart';
import 'package:scoreboard/widgets/appbar_icon.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../constants/ui_constants.dart';
import '../models/match.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Track which teams are expanded to show members and matches
  Set<int> _expandedTeams = {};

  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _teams = [];
  Map<int, List<Match>> _teamMatches = {}; // Cache for team matches
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      // Clear the team matches cache when refreshing
      _teamMatches.clear();
      // Clear expanded teams when refreshing
      _expandedTeams.clear();
    });

    try {
      final teams = await _firebaseService.getAllTeamsWithScores();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
    }
  }

  // Load matches for a specific team
  Future<void> _loadTeamMatches(int teamId) async {
    print('DEBUG: _loadTeamMatches called for team $teamId');
    print('DEBUG: Current _teamMatches state: ${_teamMatches.keys.toList()}');

    // Skip if we already have the matches cached and they're not empty
    if (_teamMatches.containsKey(teamId) && _teamMatches[teamId]!.isNotEmpty) {
      print(
          'DEBUG: Team matches already cached for team $teamId. Count: ${_teamMatches[teamId]?.length}');
      return;
    }

    print('DEBUG: Loading matches for team $teamId');
    try {
      // Set an empty list first to show we're loading
      print('DEBUG: Setting empty list for team $teamId to indicate loading');
      if (mounted) {
        setState(() {
          // Create a new map to ensure state update is detected
          _teamMatches = Map.from(_teamMatches);
          _teamMatches[teamId] = [];
        });
      }
      print(
          'DEBUG: After setState, _teamMatches contains keys: ${_teamMatches.keys.toList()}');

      print('DEBUG: Calling Firebase service to get matches for team $teamId');
      final matches = await _firebaseService.getMatchesByTeamId(teamId);
      print('DEBUG: Loaded ${matches.length} matches for team $teamId');

      // Even if no matches are found, we need to update the state with an empty list
      // to prevent infinite loading indicator
      if (mounted) {
        print('DEBUG: Widget is mounted, updating state with loaded matches');
        setState(() {
          // Create a new map to ensure state update is detected
          _teamMatches = Map.from(_teamMatches);
          // If matches is empty, we'll store an empty list with a dummy item to indicate "no matches"
          // rather than "still loading"
          _teamMatches[teamId] =
              matches.isEmpty ? [Match.empty()] : List.from(matches);
        });
        print(
            'DEBUG: After setState with matches, _teamMatches[$teamId] length: ${_teamMatches[teamId]?.length}');
      } else {
        print('DEBUG: Widget is not mounted, skipping setState');
      }
    } catch (e) {
      // On error, we still need to update the state to prevent infinite loading
      if (mounted) {
        setState(() {
          _teamMatches = Map.from(_teamMatches);
          _teamMatches[teamId] = [Match.empty()];
        });
      }
      print('DEBUG: Error loading team matches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team matches: $e')),
        );
      }
    }
  }

  // Helper method to build a match item
  Widget _buildMatchItem(Match match, int teamId) {
    // Handle empty match case
    if (match.id == -1) {
      return const SizedBox.shrink(); // Don't display empty matches
    }

    // Determine if this team is team1 or team2 in the match
    final bool isTeam1 = match.team1Id == teamId;
    final String opponentName = isTeam1 ? match.team2Name : match.team1Name;
    final int teamScore = isTeam1 ? match.team1Score : match.team2Score;
    final int opponentScore = isTeam1 ? match.team2Score : match.team1Score;

    // Determine match result
    String result = 'Scheduled';
    Color resultColor = Colors.grey;

    if (match.status == 'completed') {
      if (teamScore > opponentScore) {
        result = 'Won';
        resultColor = Colors.green;
      } else if (teamScore < opponentScore) {
        result = 'Lost';
        resultColor = Colors.red;
      } else {
        result = 'Draw';
        resultColor = Colors.orange;
      }
    } else if (match.status == 'in_progress') {
      result = 'Live';
      resultColor = Colors.blue;
    }

    // Format date
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final matchDate = match.status == 'completed' && match.completedDate != null
        ? match.completedDate!
        : match.scheduledDate;
    final formattedDate = dateFormat.format(matchDate);
    final formattedTime = timeFormat.format(matchDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$formattedDate at $formattedTime',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result,
                    style: TextStyle(
                        color: resultColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Teams and scores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'vs $opponentName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (match.status != 'scheduled')
                  Text(
                    '$teamScore - $opponentScore',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),

            // Match type
            if (match.matchType != null && match.matchType != 'regular')
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  match.matchType!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBarIcon(),
            Spacer(),
            Center(
              child: Text('Global Leaderboard'),
            ),
            Spacer(),
            SizedBox(height: 150,
            width: 150,)

          ],
        ),
        // title: const Text('Global Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => authProvider.signOut(),
            )
          else
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? const Center(child: Text('No teams found'))
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 8.0,
                      bottom: MediaQuery.of(context).padding.bottom + 80.0,
                    ),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      final rank = index + 1;
                      final isTopThree = rank <= 3;

                      final teamId = team['id'] as int;
                      final isExpanded = _expandedTeams.contains(teamId);
                      final List<Map<String, dynamic>> members =
                          List<Map<String, dynamic>>.from(
                              team['members'] ?? []);

                      return Column(
                        children: [
                          Card(
                            elevation: isTopThree ? 4 : 1,
                            margin: EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: AppPadding.getListItemPadding(context)
                                      .horizontal /
                                  2,
                            ),
                            color: isTopThree
                                ? rank == 1
                                    ? Colors.amber.shade50
                                    : rank == 2
                                        ? Colors.blueGrey.shade50
                                        : Colors.brown.shade50
                                : null,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
             
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    // Make the ListTile feel a bit more spacious to accommodate the new subtitle
                                    minVerticalPadding: 12.0,
                                    leading: CircleAvatar(
                                      backgroundColor: isTopThree
                                          ? rank == 1
                                              ? Colors.amber
                                              : rank == 2
                                                  ? Colors.blueGrey.shade300
                                                  : Colors.brown.shade300
                                          : Colors.blue,
                                      child: Text(
                                        '$rank',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      team['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    // --- FIX START: Use a Column in the subtitle for multi-line info ---
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Group: ${team['groupName']}'),
                                        const SizedBox(height: 4),
                                        // Uncomment this line if you want to show it here as well
                                        // Text(
                                        //   'Match: ${team['matchScore'] ?? 0} }',
                                        //   style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        // ),
                                        Text(
                                          'Matches: ${team['totalMatches'] ?? 0} | Matches played: ${team['completedMatches'] ?? 0} | W: ${team['wins'] ?? 0} | L: ${team['losses'] ?? 0} | D: ${team['draws'] ?? 0}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                    // --- FIX END ---
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .center, // Center items vertically
                                      children: [
                                        // --- FIX START: Simplified the trailing widget ---
                                        // The container now only holds the points, no more complex Column needed.
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${team['totalScore']} pts',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // --- FIX END ---
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(
                                            isExpanded
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              if (isExpanded) {
                                                _expandedTeams.remove(teamId);
                                              } else {
                                                _loadTeamMatches(teamId);
                                                _expandedTeams.add(teamId);
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        if (isExpanded) {
                                          _expandedTeams.remove(teamId);
                                        } else {
                                          _loadTeamMatches(teamId);
                                          _expandedTeams.add(teamId);
                                        }
                                      });
                                    },
                                  ),
                                  if (isExpanded)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      color: Colors.grey.shade100,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (members.isNotEmpty) ...[
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 8.0),
                                              child: Text(
                                                'Team Members:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            ...members.map((member) => Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 2.0),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.person,
                                                          size: 16,
                                                          color: Colors.grey),
                                                      const SizedBox(width: 8),
                                                      Text(member['name'] ??
                                                          'Unknown'),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '(${member['role'] ?? 'Member'})',
                                                        style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                )),
                                            const SizedBox(height: 16),
                                          ],
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 8.0),
                                            child: Text(
                                              'All Matches:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              if (!_teamMatches
                                                  .containsKey(teamId)) {
                                                return const Center(
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                );
                                              } else if (_teamMatches[teamId]!
                                                      .isEmpty ||
                                                  (_teamMatches[teamId]!
                                                              .length ==
                                                          1 &&
                                                      _teamMatches[teamId]![0]
                                                              .id ==
                                                          -1)) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Center(
                                                      child: Text(
                                                          'No recent matches')),
                                                );
                                              } else {
                                                final realMatches =
                                                    _teamMatches[teamId]!
                                                        .where((match) =>
                                                            match.id != -1)
                                                        .toList();
                                                return Column(
                                                  children: [
                                                    ...realMatches.map(
                                                        (match) =>
                                                            _buildMatchItem(
                                                                match, teamId)),
                                                    // if (realMatches.length > 5)
                                                    //   Padding(
                                                    //     padding:
                                                    //         const EdgeInsets
                                                    //             .only(top: 8.0),
                                                    //     child: Center(
                                                    //       child:
                                                    //           TextButton.icon(
                                                    //         icon: const Icon(
                                                    //             Icons
                                                    //                 .sports_volleyball,
                                                    //             size: 16),
                                                    //         label: const Text(
                                                    //             'View All Matches'),
                                                    //         onPressed: () {
                                                    //           ScaffoldMessenger
                                                    //                   .of(context)
                                                    //               .showSnackBar(
                                                    //             const SnackBar(
                                                    //               content: Text(
                                                    //                   'Coming soon: View all team matches'),
                                                    //             ),
                                                    //           );
                                                    //         },
                                                    //       ),
                                                    //     ),
                                                    //   ),
                                                  ],
                                                );
                                              }
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 0, vertical: 8),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                minimumSize:
                                                    const Size.fromHeight(36),
                                              ),
                                              onPressed: () {
                                                final groupId = team['groupId']
                                                        is int
                                                    ? team['groupId']
                                                    : int.parse(team['groupId']
                                                        .toString());

                                                AppRoutes
                                                    .navigateToGroupLeaderboard(
                                                  context,
                                                  groupId,
                                                  team['groupName'],
                                                );
                                              },
                                              child: const Text(
                                                  'View Group Leaderboard'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  
  }
}
