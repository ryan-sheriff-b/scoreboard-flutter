import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/team.dart';
import '../models/score.dart';
import '../providers/score_provider.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class TeamScoresScreen extends StatefulWidget {
  final Team team;
  final bool readOnly;

  const TeamScoresScreen({
    super.key, 
    required this.team,
    this.readOnly = false,
  });

  @override
  State<TeamScoresScreen> createState() => _TeamScoresScreenState();
}

class _TeamScoresScreenState extends State<TeamScoresScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _isAdmin = authProvider.isAdmin && !widget.readOnly;
      });
      Provider.of<ScoreProvider>(context, listen: false).setCurrentTeam(widget.team.id!);
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddScoreDialog() {
    _pointsController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Score'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter points';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final score = Score(
                  teamId: widget.team.id!,
                  points: int.parse(_pointsController.text),
                  description: _descriptionController.text,
                  createdAt: DateTime.now(),
                );
                await Provider.of<ScoreProvider>(context, listen: false).addScore(score);
                // Refresh the team scores list
                if (context.mounted) {
                  await Provider.of<TeamProvider>(context, listen: false)
                      .refreshTeamsWithScores();
                }
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditScoreDialog(Score score) {
    _pointsController.text = score.points.toString();
    _descriptionController.text = score.description;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Score'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter points';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final updatedScore = score.copyWith(
                  points: int.parse(_pointsController.text),
                  description: _descriptionController.text,
                );
                await Provider.of<ScoreProvider>(context, listen: false).updateScore(updatedScore);
                // Refresh the team scores list
                if (context.mounted) {
                  await Provider.of<TeamProvider>(context, listen: false)
                      .refreshTeamsWithScores();
                }
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteScore(Score score) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Score'),
        content: Text('Are you sure you want to delete this score entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<ScoreProvider>(context, listen: false).deleteScore(score.id!);
              // Refresh the team scores list
              if (context.mounted) {
                await Provider.of<TeamProvider>(context, listen: false)
                    .refreshTeamsWithScores();
              }
              if (context.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.name} Scores'),
      ),
      body: Consumer2<ScoreProvider, AuthProvider>(
        builder: (context, scoreProvider, authProvider, child) {
          // Update admin status whenever auth state changes
          _isAdmin = authProvider.isAdmin && !widget.readOnly;
          if (scoreProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Score:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '${scoreProvider.totalScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: scoreProvider.scores.isEmpty
                    ? const Center(child: Text('No scores found. Add a new score!'))
                    : ListView.builder(
                        itemCount: scoreProvider.scores.length,
                        itemBuilder: (ctx, index) {
                          final score = scoreProvider.scores[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: score.points > 0 ? Colors.green : Colors.red,
                                child: Text(
                                  score.points.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                score.description,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Added: ${DateFormat('dd/MM/yyyy').format(score.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: _isAdmin ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditScoreDialog(score),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDeleteScore(score),
                                  ),
                                ],
                              ) : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        onPressed: _showAddScoreDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}