import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/member.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

class GlobalMatchProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Match> _allMatches = [];
  bool _isLoading = false;
  bool _showCompletedOnly = false;
  
  // Cache for team members
  final Map<int, List<Member>> _teamMembersCache = {};

  List<Match> get allMatches => _allMatches;
  bool get isLoading => _isLoading;
  bool get showCompletedOnly => _showCompletedOnly;

  // Toggle between showing all matches or completed matches only
  void toggleCompletedOnly() {
    _showCompletedOnly = !_showCompletedOnly;
    fetchAllMatches();
  }
  
  // Fetch team members for a specific team
  Future<List<Member>> getTeamMembers(int teamId) async {
    // Check if we already have the members in cache
    if (_teamMembersCache.containsKey(teamId)) {
      return _teamMembersCache[teamId]!;
    }
    
    try {
      final members = await _firebaseService.getMembers(teamId);
      // Cache the result
      _teamMembersCache[teamId] = members;
      return members;
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }

  // Fetch all matches from Firebase
  Future<void> fetchAllMatches() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allMatches = await _firebaseService.getAllMatches(completedOnly: _showCompletedOnly);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching all matches: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Fetch only inter-group matches from Firebase
  Future<void> fetchInterGroupMatches() async {
    print('DEBUG: GlobalMatchProvider - Starting fetchInterGroupMatches');
    _isLoading = true;
    notifyListeners();
    
    try {
      print('DEBUG: GlobalMatchProvider - Calling _firebaseService.getInterGroupMatches');
      final matches = await _firebaseService.getInterGroupMatches(completedOnly: false);
      print('DEBUG: GlobalMatchProvider - Received ${matches.length} inter-group matches');
      
      _allMatches = matches;
      print('DEBUG: GlobalMatchProvider - Updated _allMatches, now has ${_allMatches.length} items');
      
      _isLoading = false;
      notifyListeners();
      print('DEBUG: GlobalMatchProvider - Notified listeners after updating matches');
    } catch (e) {
      print('Error fetching inter-group matches: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get winner information for a match
  Map<String, dynamic> getMatchWinner(Match match) {
    if (match.status != 'completed') {
      return {
        'hasWinner': false,
        'isDraw': false,
        'winnerName': '',
        'winnerScore': 0,
        'loserName': '',
        'loserScore': 0,
      };
    }

    if (match.team1Score == match.team2Score) {
      return {
        'hasWinner': false,
        'isDraw': true,
        'team1Name': match.team1Name,
        'team2Name': match.team2Name,
        'score': '${match.team1Score} - ${match.team2Score}',
      };
    }

    final bool team1Won = match.team1Score > match.team2Score;
    
    return {
      'hasWinner': true,
      'isDraw': false,
      'winnerName': team1Won ? match.team1Name : match.team2Name,
      'winnerScore': team1Won ? match.team1Score : match.team2Score,
      'loserName': team1Won ? match.team2Name : match.team1Name,
      'loserScore': team1Won ? match.team2Score : match.team1Score,
    };
  }
  
  // Delete a match
  Future<void> deleteMatch(int matchId) async {
    try {
      // Delete from Firebase
      await _firebaseService.deleteMatch(matchId);
      
      // Update local state
      _allMatches.removeWhere((match) => match.id == matchId);
      notifyListeners();
    } catch (e) {
      print('Error deleting match: $e');
      rethrow;
    }
  }
  
  // Update match scores
  Future<void> updateMatchScore(int matchId, int team1Score, int team2Score) async {
    try {
      final matchIndex = _allMatches.indexWhere((m) => m.id == matchId);
      if (matchIndex == -1) return;
      
      final match = _allMatches[matchIndex];
      final updatedMatch = match.copyWith(
        team1Score: team1Score,
        team2Score: team2Score,
        status: 'in_progress',
      );
      
      // Update in Firebase
      await _firebaseService.updateMatch(updatedMatch);
      
      // Update local state
      _allMatches[matchIndex] = updatedMatch;
      
      notifyListeners();
    } catch (e) {
      print('Error updating match score: $e');
      rethrow;
    }
  }

  // Complete a match
  Future<void> completeMatch(int matchId) async {
    try {
      final matchIndex = _allMatches.indexWhere((m) => m.id == matchId);
      if (matchIndex == -1) return;
      
      final match = _allMatches[matchIndex];
      final updatedMatch = match.copyWith(
        status: 'completed',
        completedDate: DateTime.now(),
      );
      
      // Update in Firebase
      await _firebaseService.updateMatch(updatedMatch);
      
      // Update local state
      _allMatches[matchIndex] = updatedMatch;
      
      notifyListeners();
    } catch (e) {
      print('Error completing match: $e');
      rethrow;
    }
  }
  
  // Get all inter-group matches
  List<Match> get interGroupMatches {
    return _allMatches.where((match) => 
      match.team1GroupId != null && 
      match.team2GroupId != null && 
      match.team1GroupId != match.team2GroupId
    ).toList();
  }
}