import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../services/firebase_service.dart';

class TeamProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Team> _teams = [];
  List<Map<String, dynamic>> _teamsWithScores = [];
  bool _isLoading = false;
  int? _currentGroupId;

  List<Team> get teams => _teams;
  List<Map<String, dynamic>> get teamsWithScores => _teamsWithScores;
  bool get isLoading => _isLoading;
  int? get currentGroupId => _currentGroupId;

  void setCurrentGroup(int groupId) {
    _currentGroupId = groupId;
    loadTeams(groupId);
  }

  Future<void> loadTeams(int groupId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _teams = await _firebaseService.getTeams(groupId);
      _teamsWithScores = await _firebaseService.getAllTeamsWithScores(groupId: groupId);
    } catch (e) {
      print('Error loading teams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTeam(Team team) async {
    try {
      final id = await _firebaseService.addTeam(team);
      // Use hashCode for stable integer ID
      final newTeam = team.copyWith(id: id.hashCode);
      _teams.add(newTeam);
      await refreshTeamsWithScores();
      notifyListeners();
    } catch (e) {
      print('Error adding team: $e');
    }
  }

  Future<void> updateTeam(Team team) async {
    try {
      await _firebaseService.updateTeam(team);
      final index = _teams.indexWhere((t) => t.id == team.id);
      if (index != -1) {
        _teams[index] = team;
        await refreshTeamsWithScores();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating team: $e');
    }
  }

  Future<void> deleteTeam(int id) async {
    try {
      await _firebaseService.deleteTeam(id);
      _teams.removeWhere((team) => team.id == id);
      await refreshTeamsWithScores();
      notifyListeners();
    } catch (e) {
      print('Error deleting team: $e');
    }
  }

  Future<void> refreshTeamsWithScores() async {
    if (_currentGroupId != null) {
      _teamsWithScores = await _firebaseService.getAllTeamsWithScores(groupId: _currentGroupId);
      notifyListeners();
    }
  }
}