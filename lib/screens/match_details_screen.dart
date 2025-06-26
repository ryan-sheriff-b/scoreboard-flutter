import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/auth_provider.dart';

class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _isAdmin = false;
  int _team1Score = 0;
  int _team2Score = 0;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshAdminStatus();
      
      setState(() {
        _isAdmin = authProvider.isAdmin;
      });
      
      // Initialize scores from the selected match
      final matchProvider = Provider.of<MatchProvider>(context, listen: false);
      final match = matchProvider.selectedMatch;
      if (match != null) {
        setState(() {
          _team1Score = match.team1Score;
          _team2Score = match.team2Score;
        });
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh scores whenever dependencies change (like when returning to this screen)
    final match = Provider.of<MatchProvider>(context, listen: false).selectedMatch;
    if (match != null) {
      setState(() {
        _team1Score = match.team1Score;
        _team2Score = match.team2Score;
      });
    }
  }

  Future<void> _updateScores(Match match) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      await Provider.of<MatchProvider>(context, listen: false)
          .updateMatchScore(match.id!, _team1Score, _team2Score);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating scores: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _completeMatch(Match match) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      await Provider.of<MatchProvider>(context, listen: false)
          .completeMatch(match.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match marked as completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing match: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteMatch(Match match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      await Provider.of<MatchProvider>(context, listen: false)
          .deleteMatch(match.id!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match deleted successfully')),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting match: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (ctx, matchProvider, _) {
        final match = matchProvider.selectedMatch;
        
        if (match == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Match Details')),
            body: const Center(child: Text('No match selected')),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Match Details'),
            actions: [
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteMatch(match),
                ),
            ],
          ),
          body: _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status and date info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _getMatchStatusColor(match.status),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getMatchStatusText(match.status),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Scheduled: ${DateFormat('yyyy-MM-dd').format(match.scheduledDate)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              if (match.completedDate != null) ...[  
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Completed: ${DateFormat('yyyy-MM-dd').format(match.completedDate!)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Teams and scores
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          match.team1Name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        _isAdmin && match.status != 'completed'
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle),
                                                    onPressed: _team1Score > 0
                                                        ? () {
                                                            setState(() {
                                                              _team1Score--;
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '$_team1Score',
                                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle),
                                                    onPressed: () {
                                                      setState(() {
                                                        _team1Score++;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              )
                                            : Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[100],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${match.team1Score}',
                                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: const Text(
                                      'VS',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          match.team2Name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        _isAdmin && match.status != 'completed'
                                            ? Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle),
                                                    onPressed: _team2Score > 0
                                                        ? () {
                                                            setState(() {
                                                              _team2Score--;
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '$_team2Score',
                                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle),
                                                    onPressed: () {
                                                      setState(() {
                                                        _team2Score++;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              )
                                            : Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.red[100],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${match.team2Score}',
                                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (_isAdmin && match.status != 'completed') ...[  
                        const SizedBox(height: 24),
                        
                        // Admin actions
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateScores(match),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Update Scores'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _completeMatch(match),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Complete Match'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}