import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/group.dart';
import '../models/team.dart';
import '../providers/team_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import 'members_screen.dart';
import 'team_scores_screen.dart';
import 'group_leaderboard_screen.dart';
import 'matches_screen.dart';

class TeamsScreen extends StatefulWidget {
  final Group group;

  const TeamsScreen({super.key, required this.group});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Refresh admin status from Firestore
      await authProvider.refreshAdminStatus();
      
      // Debug admin status
      authProvider.debugAdminStatus();
      
      // Check if user is admin
      setState(() {
        _isAdmin = authProvider.isAdmin;
      });
      
      print('TeamsScreen _isAdmin: $_isAdmin'); // Debug print
      
      Provider.of<TeamProvider>(context, listen: false).setCurrentGroup(widget.group.id!);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddTeamDialog() {
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Team'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final team = Team(
                  groupId: widget.group.id!,
                  name: _nameController.text,
                  description: _descriptionController.text,
                  createdAt: DateTime.now(),
                );
                Provider.of<TeamProvider>(context, listen: false).addTeam(team);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(Team team) {
    _nameController.text = team.name;
    _descriptionController.text = team.description;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Team'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedTeam = team.copyWith(
                  name: _nameController.text,
                  description: _descriptionController.text,
                );
                Provider.of<TeamProvider>(context, listen: false).updateTeam(updatedTeam);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTeam(Team team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete ${team.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<TeamProvider>(context, listen: false).deleteTeam(team.id!);
              Navigator.of(ctx).pop();
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
        title: Text('${widget.group.name} - Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchesScreen(
                    group: widget.group,
                  ),
                ),
              );
            },
            tooltip: 'Matches',
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupLeaderboardScreen(
                    groupId: widget.group.id!,
                    groupName: widget.group.name,
                  ),
                ),
              );
            },
            tooltip: 'Group Leaderboard',
          ),
        ],
      ),
      body: Consumer<TeamProvider>(
        builder: (ctx, teamProvider, child) {
          if (teamProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (teamProvider.teamsWithScores.isEmpty) {
            return const Center(child: Text('No teams found. Add a new team!'));
          }

          return ListView.builder(
            itemCount: teamProvider.teamsWithScores.length,
            itemBuilder: (ctx, index) {
              final teamWithScore = teamProvider.teamsWithScores[index];
              final teamId = teamWithScore['id'] as int;
              final teamName = teamWithScore['name'] as String;
              final teamDescription = teamWithScore['description'] as String;
              final totalScore = teamWithScore['totalScore'] as int;
              
              // Find the full team object
              final team = teamProvider.teams.firstWhere(
                (t) => t.id == teamId,
                orElse: () => Team(
                  id: teamId,
                  groupId: widget.group.id!,
                  name: teamName,
                  description: teamDescription,
                  createdAt: DateTime.now(),
                ),
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Text(
                            teamName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Score: $totalScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teamDescription),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${DateFormat('dd/MM/yyyy').format(team.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceEvenly,
                      children: _isAdmin
                          ? [
                              TextButton.icon(
                                icon: const Icon(Icons.people),
                                label: const Text('Members'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MembersScreen(team: team),
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.score),
                                label: const Text('Scores'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamScoresScreen(team: team),
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                onPressed: () => _showEditTeamDialog(team),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () => _confirmDeleteTeam(team),
                              ),
                            ]
                          : [
                              // For non-admin users, only show view options
                              TextButton.icon(
                                icon: const Icon(Icons.people),
                                label: const Text('View Members'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MembersScreen(
                                        team: team,
                                        readOnly: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.score),
                                label: const Text('View Scores'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TeamScoresScreen(
                                        team: team,
                                        readOnly: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        onPressed: _showAddTeamDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}