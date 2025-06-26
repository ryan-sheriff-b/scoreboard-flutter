import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';
import '../constants/ui_constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // Track which teams are expanded to show members
  Set<int> _expandedTeams = {};
  
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => authProvider.signOut(),
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
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      final rank = index + 1;
                      final isTopThree = rank <= 3;
                      
                      final teamId = team['id'] as int;
                      final isExpanded = _expandedTeams.contains(teamId);
                      final List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(team['members'] ?? []);
                      
                      return Column(
                        children: [
                          Card(
                            elevation: isTopThree ? 4 : 1,
                            margin: EdgeInsets.symmetric(
                              vertical: 4, 
                              horizontal: AppPadding.getListItemPadding(context).horizontal / 2
                            ),
                            color: isTopThree
                                ? rank == 1
                                    ? Colors.amber.shade50
                                    : rank == 2
                                        ? Colors.blueGrey.shade50
                                        : Colors.brown.shade50
                                : null,
                            child: Column(
                              children: [
                                ListTile(
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
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    team['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Group: ${team['groupName']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${team['totalScore']} pts',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (isExpanded) {
                                              _expandedTeams.remove(teamId);
                                            } else {
                                              _expandedTeams.add(teamId);
                                            }
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Toggle expansion when tapped
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedTeams.remove(teamId);
                                      } else {
                                        _expandedTeams.add(teamId);
                                      }
                                    });
                                  },
                                ),
                                // Show members when expanded
                                if (isExpanded && members.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.grey.shade100,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            'Team Members:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        ...members.map((member) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person, size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(member['name'] ?? 'Unknown'),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${member['role'] ?? 'Member'})',
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                // Button to view group leaderboard
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(36),
                                    ),
                                    onPressed: () {
                                      // Ensure groupId is passed as an int
                                      final groupId = team['groupId'] is int 
                                          ? team['groupId'] 
                                          : int.parse(team['groupId'].toString());
                                          
                                      AppRoutes.navigateToGroupLeaderboard(
                                        context,
                                        groupId,
                                        team['groupName'],
                                      );
                                    },
                                    child: const Text('View Group Leaderboard'),
                                  ),
                                ),
                              ],
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