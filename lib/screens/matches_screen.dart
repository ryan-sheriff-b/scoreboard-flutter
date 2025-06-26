import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/group.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../providers/team_provider.dart';
import '../providers/match_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../routes/routes.dart';

class MatchesScreen extends StatefulWidget {
  final Group group;

  const MatchesScreen({super.key, required this.group});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;
  bool _isLoading = true;
  List<Team> _teams = [];
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  String _selectedMatchType = 'regular';
  DateTime _scheduledDate = DateTime.now();
  int? _currentGroupId;
  
  // Match type options
  final List<Map<String, dynamic>> _matchTypes = [
    {'value': 'regular', 'label': 'Regular Match'},
    {'value': 'qualifier', 'label': 'Qualifier Match'},
    {'value': 'eliminator', 'label': 'Eliminator Match'},
    {'value': 'final', 'label': 'Final Match'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Refresh admin status from Firestore
      await authProvider.refreshAdminStatus();
      
      setState(() {
        _isAdmin = authProvider.isAdmin;
        _currentGroupId = widget.group.id!;
      });
      
      // Set current group for providers
      Provider.of<TeamProvider>(context, listen: false).setCurrentGroup(widget.group.id!);
      Provider.of<MatchProvider>(context, listen: false).setCurrentGroup(widget.group.id!);
      
      // Load teams for dropdowns
      await _loadTeams();
      
      setState(() {
        _isLoading = false;
      });
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh matches when returning to this screen
    if (_currentGroupId != null && !_isLoading) {
      Provider.of<MatchProvider>(context, listen: false).fetchMatches();
    }
  }

  Future<void> _loadTeams() async {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    // Teams should already be loaded by setCurrentGroup, but we can refresh if needed
    if (teamProvider.teams.isEmpty && _currentGroupId != null) {
      await teamProvider.loadTeams(_currentGroupId!);
    }
    setState(() {
      _teams = teamProvider.teams;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _createMatch() async {
    if (_formKey.currentState!.validate() && _selectedTeam1 != null && _selectedTeam2 != null) {
      if (_selectedTeam1!.id == _selectedTeam2!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teams must be different')),
        );
        return;
      }
      
      try {
        final match = Match(
          groupId: widget.group.id!,
          team1Id: _selectedTeam1!.id!,
          team2Id: _selectedTeam2!.id!,
          team1Name: _selectedTeam1!.name,
          team2Name: _selectedTeam2!.name,
          status: 'scheduled',
          matchType: _selectedMatchType,
          scheduledDate: _scheduledDate,
          createdAt: DateTime.now(),
        );
        
        await Provider.of<MatchProvider>(context, listen: false).addMatch(match);
        
        // Reset form
        setState(() {
          _selectedTeam1 = null;
          _selectedTeam2 = null;
          _selectedMatchType = 'regular';
          _scheduledDate = DateTime.now();
        });
        
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating match: $e')),
        );
      }
    }
  }

  void _showCreateMatchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Match'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Team>(
                  decoration: const InputDecoration(labelText: 'Team 1'),
                  value: _selectedTeam1,
                  items: _teams.map((team) {
                    return DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTeam1 = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select Team 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Team>(
                  decoration: const InputDecoration(labelText: 'Team 2'),
                  value: _selectedTeam2,
                  items: _teams.map((team) {
                    return DropdownMenuItem<Team>(
                      value: team,
                      child: Text(team.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTeam2 = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select Team 2';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Match Type'),
                  value: _selectedMatchType,
                  items: _matchTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'],
                      child: Text(type['label']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMatchType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Scheduled Date: ${DateFormat('yyyy-MM-dd').format(_scheduledDate)}',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createMatch,
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Matches - ${widget.group.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MatchProvider>(
              builder: (ctx, matchProvider, _) {
                final matches = matchProvider.matches;
                
                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No matches found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        if (_isAdmin)
                          ElevatedButton(
                            onPressed: _showCreateMatchDialog,
                            child: const Text('Create Match'),
                          ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (ctx, index) {
                          final match = matches[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Row(
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(match.scheduledDate),
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
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Select the match and navigate to details
                                matchProvider.selectMatch(match);
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.matchDetails,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    if (_isAdmin)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: _showCreateMatchDialog,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('Create New Match'),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}