import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  StreamSubscription? _matchSubscription;
  
  // Controllers for text fields
  late TextEditingController _team1ScoreController;
  late TextEditingController _team2ScoreController;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _team1ScoreController = TextEditingController(text: '0');
    _team2ScoreController = TextEditingController(text: '0');
    
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
          _team1ScoreController.text = '${match.team1Score}';
          _team2ScoreController.text = '${match.team2Score}';
        });
        
        // Set up real-time listener for match updates if match is in progress
        if (match.status == 'in_progress') {
          _setupMatchListener(match.id!);
        }
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
        _team1ScoreController.text = '${match.team1Score}';
        _team2ScoreController.text = '${match.team2Score}';
      });
      
      // Set up or cancel real-time listener based on match status
      if (match.status == 'in_progress') {
        _setupMatchListener(match.id!);
      } else {
        // Cancel the subscription if the match is no longer in progress
        _matchSubscription?.cancel();
        _matchSubscription = null;
      }
    }
  }
  
  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _team1ScoreController.dispose();
    _team2ScoreController.dispose();
    
    // Cancel the match subscription if it exists
    _matchSubscription?.cancel();
    
    super.dispose();
  }
  
  void _setupMatchListener(int matchId) {
    // Cancel any existing subscription
    _matchSubscription?.cancel();
    
    // Set up a real-time listener for the match document
    _matchSubscription = FirebaseFirestore.instance
        .collection('matches')
        .where('id', isEqualTo: matchId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final matchData = snapshot.docs.first.data() as Map<String, dynamic>;
            final String status = matchData['status'] ?? 'scheduled';
            
            // Check if match status has changed from in_progress
            if (status != 'in_progress') {
              // Cancel subscription if match is no longer in progress
              _matchSubscription?.cancel();
              _matchSubscription = null;
              return;
            }
            
            // Only update if the scores have changed
            final newTeam1Score = matchData['team1Score'] ?? 0;
            final newTeam2Score = matchData['team2Score'] ?? 0;
            
            if (newTeam1Score != _team1Score || newTeam2Score != _team2Score) {
              setState(() {
                _team1Score = newTeam1Score;
                _team2Score = newTeam2Score;
                _team1ScoreController.text = '$newTeam1Score';
                _team2ScoreController.text = '$newTeam2Score';
              });
              
              // Show a notification about the score update
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Match scores updated in real-time'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }
        }, onError: (error) {
          print('Error listening to match updates: $error');
        });
  }

  Future<void> _updateScores(Match match) async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      final updatedMatch = await Provider.of<MatchProvider>(context, listen: false)
          .updateMatchScore(match.id!, _team1Score, _team2Score);
      
      // Set up real-time listener if the match is now in progress
      if (updatedMatch.status == 'in_progress' && _matchSubscription == null) {
        _setupMatchListener(match.id!);
      }
      
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
      final updatedMatch = await Provider.of<MatchProvider>(context, listen: false)
          .completeMatch(match.id!);
      
      // Cancel the real-time listener since the match is now completed
      _matchSubscription?.cancel();
      _matchSubscription = null;
      
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

  Future<void> _updateScheduledDateTime(Match match) async {
    if (_isUpdating) return;
    
    // First, select the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: match.scheduledDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      // Then, select the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(match.scheduledDate),
      );
      
      if (pickedTime != null) {
        // Combine date and time
        final DateTime newScheduledDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          _isUpdating = true;
        });
        
        try {
          // Create updated match with new scheduled date
          final updatedMatch = match.copyWith(
            scheduledDate: newScheduledDate,
          );
          
          // Update in provider
          await Provider.of<MatchProvider>(context, listen: false)
              .updateMatch(updatedMatch);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule updated successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating schedule: $e')),
          );
        } finally {
          setState(() {
            _isUpdating = false;
          });
        }
      }
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
                  if (match.status == 'in_progress' && _matchSubscription != null) ...[  
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('REAL-TIME UPDATES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Scheduled: ${DateFormat('dd/MM/yyyy hh:mm a').format(match.scheduledDate)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  if (_isAdmin && match.status != 'completed')
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      tooltip: 'Update Schedule',
                                      onPressed: () => _updateScheduledDateTime(match),
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
                                      'Completed: ${DateFormat('dd/MM/yyyy hh:mm a').format(match.completedDate!)}',
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
                                                  if (match.status == 'in_progress' && _matchSubscription != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      margin: const EdgeInsets.only(right: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.sync, color: Colors.white, size: 12),
                                                          SizedBox(width: 4),
                                                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle),
                                                    onPressed: _team1Score > 0
                                                        ? () {
                                                            setState(() {
                                                              _team1Score--;
                                                              _team1ScoreController.text = '$_team1Score';
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  Container(
                                                    width: 80,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: TextField(
                                                      textAlign: TextAlign.center,
                                                      keyboardType: TextInputType.number,
                                                      controller: _team1ScoreController,
                                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                      decoration: const InputDecoration(
                                                        border: InputBorder.none,
                                                        contentPadding: EdgeInsets.zero,
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _team1Score = int.tryParse(value) ?? 0;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle),
                                                    onPressed: () {
                                                      setState(() {
                                                        _team1Score++;
                                                        _team1ScoreController.text = '$_team1Score';
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
                                                  if (match.status == 'in_progress' && _matchSubscription != null)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      margin: const EdgeInsets.only(right: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.sync, color: Colors.white, size: 12),
                                                          SizedBox(width: 4),
                                                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ],
                                                      ),
                                                    ),
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle),
                                                    onPressed: _team2Score > 0
                                                        ? () {
                                                            setState(() {
                                                              _team2Score--;
                                                              _team2ScoreController.text = '$_team2Score';
                                                            });
                                                          }
                                                        : null,
                                                  ),
                                                  Container(
                                                    width: 80,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: TextField(
                                                      textAlign: TextAlign.center,
                                                      keyboardType: TextInputType.number,
                                                      controller: _team2ScoreController,
                                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                      decoration: const InputDecoration(
                                                        border: InputBorder.none,
                                                        contentPadding: EdgeInsets.zero,
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _team2Score = int.tryParse(value) ?? 0;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle),
                                                    onPressed: () {
                                                      setState(() {
                                                        _team2Score++;
                                                        _team2ScoreController.text = '$_team2Score';
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