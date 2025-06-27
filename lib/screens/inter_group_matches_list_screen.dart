import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scoreboard/widgets/appbar_icon.dart';

import '../models/match.dart';
import '../providers/global_match_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/routes.dart';
import '../constants/ui_constants.dart';

class InterGroupMatchesListScreen extends StatefulWidget {
  const InterGroupMatchesListScreen({super.key});

  @override
  State<InterGroupMatchesListScreen> createState() => _InterGroupMatchesListScreenState();
}

class _InterGroupMatchesListScreenState extends State<InterGroupMatchesListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch only inter-group matches when the screen is first loaded
    Future.microtask(() {
      Provider.of<GlobalMatchProvider>(context, listen: false).fetchInterGroupMatches();
    });
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

  Future<void> _confirmDelete(BuildContext context, Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete the match between ${match.team1Name} and ${match.team2Name}?\n\n'
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && match.id != null) {
      try {
        await Provider.of<GlobalMatchProvider>(context, listen: false).deleteMatch(match.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting match: $e')),
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
        toolbarHeight: 100,
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppBarIcon(),
            Spacer(),
            Center(
              child: Text('Inter-Group Matches'),
            ),
            Spacer(),
            SizedBox(height: 150,
            width: 150,)

          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Reset the GlobalMatchProvider before navigating back
            Provider.of<GlobalMatchProvider>(context, listen: false).setupMatchesStream();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Only show the create button for admin users
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create New Inter-Group Match',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.interGroupMatches);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GlobalMatchProvider>(context, listen: false)
                  .fetchInterGroupMatches();
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
          print('DEBUG: InterGroupMatchesListScreen - Consumer builder called');
          if (matchProvider.isLoading) {
            print('DEBUG: InterGroupMatchesListScreen - Loading state is true');
            return const Center(child: CircularProgressIndicator());
          }

          final matches = matchProvider.interGroupMatches;
          print('DEBUG: InterGroupMatchesListScreen - Received ${matches.length} matches from provider');
          
          // Debug: Print details of each match
          for (var match in matches) {
            print('DEBUG: InterGroupMatchesListScreen - Match ID: ${match.id}, team1: ${match.team1Name}, team2: ${match.team2Name}, team1GroupId: ${match.team1GroupId}, team2GroupId: ${match.team2GroupId}');
          }

          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No inter-group matches found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      // Only show the create button for admin users
                      if (authProvider.isAdmin) {
                        return ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.interGroupMatches);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Inter-Group Match'),
                        );
                      } else {
                        return const Text(
                          'Only administrators can create inter-group matches',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          textAlign: TextAlign.center,
                        );
                      }
                    },
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

              return Dismissible(
                key: Key('match-${match.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text(
                        'Are you sure you want to delete the match between ${match.team1Name} and ${match.team2Name}?\n\n'
                        'This action cannot be undone.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  if (match.id != null) {
                    try {
                      await Provider.of<GlobalMatchProvider>(context, listen: false).deleteMatch(match.id!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Match deleted successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting match: $e')),
                      );
                    }
                  }
                },
                child: Card(
                  margin: AppPadding.getListItemPadding(context),
                  child: ListTile(
                    onTap: () {
                      AppRoutes.navigateToInterGroupMatchDetails(context, match);
                    },
                    contentPadding: const EdgeInsets.all(16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Match type badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Inter-Group Match',
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
                              child: Text(
                                '${match.team1Score} - ${match.team2Score}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                          const Spacer(),
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
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, match),
                            tooltip: 'Delete Match',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}