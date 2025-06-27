import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scoreboard/widgets/appbar_icon.dart';

import '../models/match.dart';
import '../providers/global_match_provider.dart';
import '../providers/auth_provider.dart';

class InterGroupMatchDetailsScreen extends StatefulWidget {
  final Match match;

  const InterGroupMatchDetailsScreen({super.key, required this.match});

  @override
  State<InterGroupMatchDetailsScreen> createState() => _InterGroupMatchDetailsScreenState();
}

class _InterGroupMatchDetailsScreenState extends State<InterGroupMatchDetailsScreen> {
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
        _team1Score = widget.match.team1Score;
        _team2Score = widget.match.team2Score;
      });
    });
  }

  Future<void> _updateScores() async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Use the GlobalMatchProvider to update scores
      await Provider.of<GlobalMatchProvider>(context, listen: false)
          .updateMatchScore(widget.match.id!, _team1Score, _team2Score);
      
      // Refresh the matches list
      await Provider.of<GlobalMatchProvider>(context, listen: false)
          .fetchInterGroupMatches();
      
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

  Future<void> _completeMatch() async {
    if (_isUpdating) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // First update the scores
      await Provider.of<GlobalMatchProvider>(context, listen: false)
          .updateMatchScore(widget.match.id!, _team1Score, _team2Score);
      
      // Then complete the match
      await Provider.of<GlobalMatchProvider>(context, listen: false)
          .completeMatch(widget.match.id!);
      
      // Refresh the matches list
      await Provider.of<GlobalMatchProvider>(context, listen: false)
          .fetchInterGroupMatches();
      
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

  Future<void> _deleteMatch() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text('Are you sure you want to delete this match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirmed) return;
    
    try {
      // Use the GlobalMatchProvider to delete the match
      await Provider.of<GlobalMatchProvider>(context, listen: false)
          .deleteMatch(widget.match.id!);
      
      // Navigate back to the matches list
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting match: $e')),
        );
      }
    }
  }

  Future<void> _updateScheduledDateTime() async {
    if (_isUpdating) return;
    
    // First, select the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.match.scheduledDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null) {
      // Then, select the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.match.scheduledDate),
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
          final updatedMatch = widget.match.copyWith(
            scheduledDate: newScheduledDate,
          );
          
          // Update in provider
          await Provider.of<GlobalMatchProvider>(context, listen: false)
              .updateMatch(updatedMatch);
          
          // Refresh the matches list
          await Provider.of<GlobalMatchProvider>(context, listen: false)
              .fetchInterGroupMatches();
          
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

  @override
  Widget build(BuildContext context) {
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
              child: Text('Inter-Group Match Detail'),
            ),
            Spacer(),
            SizedBox(height: 150,
            width: 150,)

          ],
        ),
        // title: const Text('Inter-Group Match Details'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteMatch,
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
                                  color: _getMatchStatusColor(widget.match.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getMatchStatusText(widget.match.status),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Inter-Group Match - ${_getMatchTypeText(widget.match.matchType)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Scheduled: ${DateFormat('dd/MM/yyyy hh:mm a').format(widget.match.scheduledDate)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              if (_isAdmin && widget.match.status != 'completed')
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Update Schedule',
                                  onPressed: _updateScheduledDateTime,
                                ),
                            ],
                          ),
                          if (widget.match.completedDate != null) ...[  
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.check_circle),
                                const SizedBox(width: 8),
                                Text(
                                  'Completed: ${DateFormat('dd/MM/yyyy hh:mm a').format(widget.match.completedDate!)}',
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
                  
                  // Group information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Group Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Team 1 Group',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Group ID: ${widget.match.team1GroupId}'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Team 2 Group',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Group ID: ${widget.match.team2GroupId}'),
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
                                      widget.match.team1Name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    _isAdmin && widget.match.status != 'completed'
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
                                              '${widget.match.team1Score}',
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
                                      widget.match.team2Name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    _isAdmin && widget.match.status != 'completed'
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
                                              '${widget.match.team2Score}',
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
                  
                  if (_isAdmin && widget.match.status != 'completed') ...[  
                    const SizedBox(height: 24),
                    
                    // Admin actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateScores,
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
                            onPressed: _completeMatch,
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
  }
}