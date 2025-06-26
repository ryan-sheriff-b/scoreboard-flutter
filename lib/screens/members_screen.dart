import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/team.dart';
import '../models/member.dart';
import '../providers/member_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class MembersScreen extends StatefulWidget {
  final Team team;
  final bool readOnly;

  const MembersScreen({
    super.key, 
    required this.team, 
    this.readOnly = false,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
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
      Provider.of<MemberProvider>(context, listen: false).setCurrentTeam(widget.team.id!);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _showAddMemberDialog() {
    _nameController.clear();
    _roleController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Member'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Member Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a role';
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
                final member = Member(
                  teamId: widget.team.id!,
                  name: _nameController.text,
                  role: _roleController.text,
                  createdAt: DateTime.now(),
                );
                Provider.of<MemberProvider>(context, listen: false).addMember(member);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(Member member) {
    _nameController.text = member.name;
    _roleController.text = member.role;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Member'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Member Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a role';
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
                final updatedMember = member.copyWith(
                  name: _nameController.text,
                  role: _roleController.text,
                );
                Provider.of<MemberProvider>(context, listen: false).updateMember(updatedMember);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMember(Member member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MemberProvider>(context, listen: false).deleteMember(member.id!);
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
        title: Text('${widget.team.name} Members'),
      ),
      body: Consumer2<MemberProvider, AuthProvider>(
        builder: (context, memberProvider, authProvider, child) {
          // Update admin status whenever auth state changes
          _isAdmin = authProvider.isAdmin && !widget.readOnly;
          if (memberProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (memberProvider.members.isEmpty) {
            return const Center(child: Text('No members found. Add a new member!'));
          }

          return ListView.builder(
            itemCount: memberProvider.members.length,
            itemBuilder: (ctx, index) {
              final member = memberProvider.members[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(member.name[0].toUpperCase()),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${member.role}'),
                      const SizedBox(height: 4),
                      Text(
                        'Added: ${DateFormat('dd/MM/yyyy').format(member.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: _isAdmin ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditMemberDialog(member),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteMember(member),
                      ),
                    ],
                  ) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        onPressed: _showAddMemberDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}