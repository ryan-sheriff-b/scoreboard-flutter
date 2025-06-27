import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scoreboard/widgets/appbar_icon.dart';

import '../models/group.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../providers/group_provider.dart';
import '../providers/team_provider.dart';
import '../providers/match_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/global_match_provider.dart';
import '../services/firebase_service.dart';
import '../routes/routes.dart';
import '../constants/ui_constants.dart';

class InterGroupMatchesScreen extends StatefulWidget {
  const InterGroupMatchesScreen({super.key});

  @override
  State<InterGroupMatchesScreen> createState() => _InterGroupMatchesScreenState();
}

class _InterGroupMatchesScreenState extends State<InterGroupMatchesScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  
  // Groups and teams data
  List<Group> _groups = [];
  Map<int, List<Team>> _groupTeams = {};
  
  // Selected values for the form
  Group? _selectedGroup1;
  Group? _selectedGroup2;
  Team? _selectedTeam1;
  Team? _selectedTeam2;
  String _selectedMatchType = 'regular';
  DateTime _scheduledDate = DateTime.now();
  
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
    
    // Check if the user is an admin, if not redirect to the matches list screen
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only administrators can create inter-group matches')),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.interGroupMatchesList);
        return;
      }
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all groups
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      await groupProvider.loadGroups();
      _groups = groupProvider.groups;

      // Clear existing team data
      _groupTeams.clear();
      
      // Load teams for each group
      for (var group in _groups) {
        if (group.id != null) {
          final teams = await _firebaseService.getTeams(group.id!);
          _groupTeams[group.id!] = teams;
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // First, select the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'SELECT MATCH DATE',
      confirmText: 'NEXT: SELECT TIME',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerHelpStyle: const TextStyle(fontSize: 16),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      // Then, select the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate),
        helpText: 'SELECT MATCH TIME',
        confirmText: 'CONFIRM',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                helpTextStyle: const TextStyle(fontSize: 16),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (pickedTime != null) {
        // Combine date and time
        setState(() {
          _scheduledDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        // User selected date but canceled time selection
        // Still update the date but keep the original time
        setState(() {
          _scheduledDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _scheduledDate.hour,
            _scheduledDate.minute,
          );
        });
      }
    }
  }

  Future<void> _createMatch() async {
    if (_formKey.currentState!.validate() && 
        _selectedGroup1 != null && 
        _selectedGroup2 != null && 
        _selectedTeam1 != null && 
        _selectedTeam2 != null) {
      
      if (_selectedTeam1!.id == _selectedTeam2!.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teams must be different')),
        );
        return;
      }
      
      try {
        // For inter-group matches, we'll use the first group's ID as the groupId
        // This is a design decision - we could also create a special group for inter-group matches
        final match = Match(
          groupId: _selectedGroup1!.id!,
          team1Id: _selectedTeam1!.id!,
          team2Id: _selectedTeam2!.id!,
          team1GroupId: _selectedGroup1!.id!,
          team2GroupId: _selectedGroup2!.id!,
          team1Name: '${_selectedTeam1!.name} (${_selectedGroup1!.name})',
          team2Name: '${_selectedTeam2!.name} (${_selectedGroup2!.name})',
          status: 'scheduled',
          matchType: _selectedMatchType,
          scheduledDate: _scheduledDate,
          createdAt: DateTime.now(),
        );
        
        await _firebaseService.addMatch(match);
        
        // Reset form
        setState(() {
          _selectedGroup1 = null;
          _selectedGroup2 = null;
          _selectedTeam1 = null;
          _selectedTeam2 = null;
          _selectedMatchType = 'regular';
          _scheduledDate = DateTime.now();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inter-group match created successfully')),
        );
        
        // Navigate to the inter-group matches list screen
        Navigator.of(context).pushReplacementNamed(AppRoutes.interGroupMatchesList);
        
        // Refresh the inter-group matches list
        Provider.of<GlobalMatchProvider>(context, listen: false).fetchInterGroupMatches();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating match: $e')),
        );
      }
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
              child: Text('Create Inter-Group Match'),
            ),
            Spacer(),
            SizedBox(height: 150,
            width: 150,)

          ],
        ),
        // title: const Text('Create Inter-Group Match'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View Inter-Group Matches',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.interGroupMatchesList);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create a match between teams from different groups',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppPadding.largeSpacing),
                    
                    // Group 1 selection
                    const Text('First Group', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: AppPadding.smallSpacing),
                    DropdownButtonFormField<Group>(
                      decoration: const InputDecoration(
                        labelText: 'Select Group 1',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedGroup1,
                      items: _groups.map((group) {
                        return DropdownMenuItem<Group>(
                          value: group,
                          child: Text(group.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup1 = value;
                          _selectedTeam1 = null; // Reset team selection when group changes
                          
                          // If the same group is selected for both dropdowns, reset group 2
                          if (_selectedGroup2 != null && value != null && _selectedGroup2!.id == value.id) {
                            _selectedGroup2 = null;
                            _selectedTeam2 = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select Group 1';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppPadding.smallSpacing * 2),
                    
                    // Team 1 selection (only enabled if group 1 is selected)
                    DropdownButtonFormField<Team>(
                      decoration: const InputDecoration(
                        labelText: 'Select Team 1',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTeam1,
                      items: _selectedGroup1 != null && _selectedGroup1!.id != null && _groupTeams.containsKey(_selectedGroup1!.id)
                          ? _groupTeams[_selectedGroup1!.id]!.map((team) {
                              return DropdownMenuItem<Team>(
                                value: team,
                                child: Text(team.name),
                              );
                            }).toList()
                          : [],
                      onChanged: _selectedGroup1 != null
                          ? (value) {
                              setState(() {
                                _selectedTeam1 = value;
                              });
                            }
                          : null,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select Team 1';
                        }
                        // Ensure the team belongs to the selected group
                        if (_selectedGroup1 != null && value.groupId != _selectedGroup1!.id) {
                          return 'Team must belong to Group 1';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppPadding.largeSpacing + AppPadding.smallSpacing),
                    
                    // Group 2 selection
                    const Text('Second Group', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: AppPadding.smallSpacing),
                    DropdownButtonFormField<Group>(
                      decoration: const InputDecoration(
                        labelText: 'Select Group 2',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedGroup2,
                      items: _groups.map((group) {
                        return DropdownMenuItem<Group>(
                          value: group,
                          child: Text(group.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup2 = value;
                          _selectedTeam2 = null; // Reset team selection when group changes
                          
                          // If the same group is selected for both dropdowns, reset group 1
                          if (_selectedGroup1 != null && value != null && _selectedGroup1!.id == value.id) {
                            _selectedGroup1 = null;
                            _selectedTeam1 = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select Group 2';
                        }
                        if (_selectedGroup1 != null && value.id == _selectedGroup1!.id) {
                          return 'Please select a different group';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppPadding.smallSpacing * 2),
                    
                    // Team 2 selection (only enabled if group 2 is selected)
                    DropdownButtonFormField<Team>(
                      decoration: const InputDecoration(
                        labelText: 'Select Team 2',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTeam2,
                      items: _selectedGroup2 != null && _selectedGroup2!.id != null && _groupTeams.containsKey(_selectedGroup2!.id)
                          ? _groupTeams[_selectedGroup2!.id]!.map((team) {
                              return DropdownMenuItem<Team>(
                                value: team,
                                child: Text(team.name),
                              );
                            }).toList()
                          : [],
                      onChanged: _selectedGroup2 != null
                          ? (value) {
                              setState(() {
                                _selectedTeam2 = value;
                              });
                            }
                          : null,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select Team 2';
                        }
                        // Ensure the team belongs to the selected group
                        if (_selectedGroup2 != null && value.groupId != _selectedGroup2!.id) {
                          return 'Team must belong to Group 2';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppPadding.largeSpacing + AppPadding.smallSpacing),
                    
                    // Match Type selection
                    const Text('Match Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: AppPadding.smallSpacing),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Match Type',
                        border: OutlineInputBorder(),
                      ),
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
                    SizedBox(height: AppPadding.largeSpacing + AppPadding.smallSpacing),
                    
                    // Date and Time selection
                    const Text('Match Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: AppPadding.smallSpacing),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy hh:mm a').format(_scheduledDate),
                        ),
                      ),
                    ),
                    SizedBox(height: AppPadding.largeSpacing + AppPadding.smallSpacing),
                    
                    // Create button
                    ElevatedButton(
                      onPressed: _createMatch,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppPadding.smallSpacing * 2),
                      ),
                      child: const Text('Create Inter-Group Match'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}