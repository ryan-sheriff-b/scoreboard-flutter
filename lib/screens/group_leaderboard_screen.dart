import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class GroupLeaderboardScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const GroupLeaderboardScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupLeaderboardScreen> createState() => _GroupLeaderboardScreenState();
}

class _GroupLeaderboardScreenState extends State<GroupLeaderboardScreen> {
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
      final teams = await _firebaseService.getTeamsWithScores(widget.groupId);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? const Center(child: Text('No teams found in this group'))
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
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
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
                                  subtitle: Text(team['description'] ?? ''),
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