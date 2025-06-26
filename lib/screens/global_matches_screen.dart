import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../models/member.dart';
import '../providers/global_match_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';

class GlobalMatchesScreen extends StatefulWidget {
  const GlobalMatchesScreen({super.key});

  @override
  State<GlobalMatchesScreen> createState() => _GlobalMatchesScreenState();
}

class _GlobalMatchesScreenState extends State<GlobalMatchesScreen> {
  // Map to track expanded state of team members sections
  final Map<int, bool> _expandedTeams = {};
  @override
  void initState() {
    super.initState();
    // The GlobalMatchProvider now automatically sets up a real-time stream
    // in its constructor, so we don't need to call fetchAllMatches() here.
    // The stream will provide real-time updates for all matches.
  }

  String _getMatchStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  Color _getMatchStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  Color _getMatchTypeColor(String? matchType) {
    switch (matchType) {
      case 'qualifier':
        return Colors.purple;
      case 'eliminator':
        return Colors.deepOrange;
      case 'final':
        return Colors.red;
      case 'regular':
      default:
        return Colors.blue;
    }
  }
  
  String _getMatchTypeText(String? matchType) {
    switch (matchType) {
      case 'qualifier':
        return 'Qualifier';
      case 'eliminator':
        return 'Eliminator';
      case 'final':
        return 'Final';
      case 'regular':
      default:
        return 'Regular';
    }
  }

  Widget _buildWinnerInfo(Match match, Map<String, dynamic> winnerInfo) {
    if (match.status != 'completed') {
      return const SizedBox.shrink();
    }

    if (winnerInfo['isDraw']) {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Draw: ${winnerInfo['team1Name']} and ${winnerInfo['team2Name']} (${winnerInfo['score']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Winner: ${winnerInfo['winnerName']} (${winnerInfo['winnerScore']} - ${winnerInfo['loserScore']})',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build detailed match information section
  Widget _buildDetailedMatchInfo(Match match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Match Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Match ID', '${match.id}'),
        _buildDetailRow('Status', _getMatchStatusText(match.status)),
        _buildDetailRow('Scheduled Date', DateFormat('dd/MM/yyyy hh:mm a').format(match.scheduledDate)),
        if (match.completedDate != null)
          _buildDetailRow('Completed Date', DateFormat('dd/MM/yyyy hh:mm a').format(match.completedDate!)),
        _buildDetailRow('Created At', DateFormat('dd/MM/yyyy hh:mm a').format(match.createdAt)),
      ],
    );
  }
  
  // Helper method to build a detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build team members section
  Widget _buildTeamMembersSection(int teamId, String teamName) {
    return FutureBuilder<List<Member>>(
      future: Provider.of<GlobalMatchProvider>(context, listen: false).getTeamMembers(teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Text('Error loading team members: ${snapshot.error}');
        }
        
        final members = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  '$teamName Team',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No team members found'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: Text(member.role),
                  );
                },
              ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Match History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Inter-Group Matches',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.interGroupMatchesList);
            },
          ),
          Consumer<GlobalMatchProvider>(builder: (ctx, provider, _) {
            return IconButton(
              icon: Icon(
                provider.showCompletedOnly
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
              tooltip: provider.showCompletedOnly
                  ? 'Showing completed matches only'
                  : 'Showing all matches',
              onPressed: () {
                provider.toggleCompletedOnly();
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GlobalMatchProvider>(context, listen: false)
                  .fetchAllMatches();
            },
          ),
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Sign Out',
              onPressed: () => authProvider.signOut(),
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Sign In',
              onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            ),
        ],
      ),
      body: Consumer<GlobalMatchProvider>(
        builder: (ctx, matchProvider, _) {
          if (matchProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = matchProvider.allMatches;

          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    matchProvider.showCompletedOnly
                        ? 'No completed matches found'
                        : 'No matches found',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (ctx, index) {
              final match = matches[index];
              final winnerInfo = matchProvider.getMatchWinner(match);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group name and match type
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.team1GroupId != null && match.team2GroupId != null && match.team1GroupId != match.team2GroupId
                                  ? 'Inter-Group Match'
                                  : 'Group: Group ${match.groupId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMatchTypeColor(match.matchType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getMatchTypeText(match.matchType),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Match teams and score
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.team1Name,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${match.team1Score} - ${match.team2Score}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (match.status == 'in_progress') ...[  
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.sync, color: Colors.white, size: 10),
                                        SizedBox(width: 2),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.team2Name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      
                      // Winner information
                      _buildWinnerInfo(match, winnerInfo),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy hh:mm a').format(match.scheduledDate),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (match.completedDate != null) ...[  
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed: ${DateFormat('dd/MM/yyyy hh:mm a').format(match.completedDate!)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getMatchStatusColor(match.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getMatchStatusText(match.status),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            if (match.status == 'in_progress') ...[  
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync, color: Colors.white, size: 10),
                                    SizedBox(width: 2),
                                    Text(
                                      'REAL-TIME',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  children: [
                    const Divider(),
                    // Detailed match information
                    _buildDetailedMatchInfo(match),
                    
                    // Team members sections
                    const SizedBox(height: 16),
                    _buildTeamMembersSection(match.team1Id, match.team1Name),
                    const SizedBox(height: 16),
                    _buildTeamMembersSection(match.team2Id, match.team2Name),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}