import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:scoreboard/screens/group_leaderboard_screen.dart';

import '../models/group.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/global_match_provider.dart';
import '../services/firebase_service.dart';
import '../routes/routes.dart';
import '../constants/ui_constants.dart';
import 'teams_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    
    // Use a post-frame callback to ensure the widget is fully built before refreshing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Refresh admin status from Firestore
      await authProvider.refreshAdminStatus();
      
      // Debug admin status
      authProvider.debugAdminStatus();
      print('GroupsScreen - Admin status after refresh: ${authProvider.isAdmin}'); // Debug print
      
      // Load groups from Firestore
      Provider.of<GroupProvider>(context, listen: false).loadGroups();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddGroupDialog() {
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Group'),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppPadding.mediumSpacing,
          vertical: AppPadding.smallSpacing,
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppPadding.smallSpacing * 2),
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
                final group = Group(
                  name: _nameController.text,
                  description: _descriptionController.text,
                  createdAt: DateTime.now(),
                );
                Provider.of<GroupProvider>(context, listen: false).addGroup(group);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(Group group) {
    _nameController.text = group.name;
    _descriptionController.text = group.description;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Group'),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppPadding.mediumSpacing,
          vertical: AppPadding.smallSpacing,
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppPadding.smallSpacing * 2),
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
                final updatedGroup = group.copyWith(
                  name: _nameController.text,
                  description: _descriptionController.text,
                );
                Provider.of<GroupProvider>(context, listen: false).updateGroup(updatedGroup);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete ${group.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GroupProvider>(context, listen: false).deleteGroup(group.id!);
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
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          // Admin toggle button for testing
          TextButton.icon(
            icon: Icon(
              authProvider.isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: Colors.white,
            ),
            label: Text(
              authProvider.isAdmin ? 'Admin' : 'User',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              // Toggle admin status
              await authProvider.setAdminStatus(!authProvider.isAdmin);
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.leaderboard),
          //   onPressed: () => Navigator.of(context).pushNamed(AppRoutes.leaderboard),
          //   tooltip: 'Global Leaderboard',
          // ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Load global matches before navigating
              Provider.of<GlobalMatchProvider>(context, listen: false).fetchAllMatches();
              Navigator.of(context).pushNamed(AppRoutes.globalMatches);
            },
            tooltip: 'Match History',
          ),
          // Add button for creating inter-group matches (only for admins)
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.sports_soccer),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.interGroupMatches),
              tooltip: 'Create Inter-Group Match',
            ),
          // Add button for viewing inter-group matches
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.interGroupMatchesList),
            tooltip: 'Inter-Group Matches',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (ctx, groupProvider, child) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groupProvider.groups.isEmpty) {
            return const Center(child: Text('No groups found. Add a new group!'));
          }

          return ListView.builder(
            itemCount: groupProvider.groups.length,
            itemBuilder: (ctx, index) {
              final group = groupProvider.groups[index];
              return Card(
                margin: AppPadding.getListItemPadding(context),
                child: ListTile(
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.description),
                      SizedBox(height: AppPadding.smallSpacing / 2),
                      Text(
                        'Created: ${DateFormat('dd/MM/yyyy').format(group.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      if (authProvider.isAdmin) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.sports_soccer, color: Colors.green),
                              tooltip: 'Matches',
                              onPressed: () => AppRoutes.navigateToMatches(context, group.id!, group.name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditGroupDialog(group),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteGroup(group),
                            ),
                          ],
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(Icons.sports_soccer, color: Colors.green),
                          tooltip: 'Matches',
                          onPressed: () => AppRoutes.navigateToMatches(context, group.id!, group.name),
                        );
                      }
                    },
                  ),
                  onTap: () {
                    // Use a Consumer inline to get the latest admin status
                    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
                    if (isAdmin) {
                      // For admin users, navigate to teams management
                      AppRoutes.navigateToTeams(context, group.id!, group.name);
                    } else {
                      // For non-admin users, show the group leaderboard
                      AppRoutes.navigateToGroupLeaderboard(context, group.id!, group.name);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          print('FAB Consumer rebuild - isAdmin: ${authProvider.isAdmin}');
          if (authProvider.isAdmin) {
            return FloatingActionButton(
              onPressed: _showAddGroupDialog,
              child: const Icon(Icons.add),
            );
          } else {
            return const SizedBox.shrink(); // Return an empty widget instead of null
          }
        },
      ),
    );
  }
}