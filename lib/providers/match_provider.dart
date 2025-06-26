import 'package:flutter/foundation.dart';
import '../models/match.dart';
import '../services/firebase_service.dart';

class MatchProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Match> _matches = [];
  int? _currentGroupId;
  Match? _selectedMatch;

  List<Match> get matches => _matches;
  Match? get selectedMatch => _selectedMatch;

  void setCurrentGroup(int groupId) {
    _currentGroupId = groupId;
    fetchMatches();
  }

  void selectMatch(Match match) {
    _selectedMatch = match;
    notifyListeners();
  }

  Future<void> fetchMatches() async {
    if (_currentGroupId == null) return;
    
    try {
      _matches = await _firebaseService.getMatches(_currentGroupId!);
      notifyListeners();
    } catch (e) {
      print('Error fetching matches: $e');
    }
  }

  Future<void> addMatch(Match match) async {
    try {
      await _firebaseService.addMatch(match);
      await fetchMatches();
    } catch (e) {
      print('Error adding match: $e');
      rethrow;
    }
  }

  Future<void> updateMatch(Match match) async {
    try {
      // Update in Firebase
      await _firebaseService.updateMatch(match);
      
      // Update local state
      final matchIndex = _matches.indexWhere((m) => m.id == match.id);
      if (matchIndex != -1) {
        _matches[matchIndex] = match;
      }
      
      // Refresh from Firebase to ensure consistency
      await fetchMatches();
      
      // Update selected match if it's the one being updated
      if (_selectedMatch != null && _selectedMatch!.id == match.id) {
        _selectedMatch = match;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating match: $e');
      rethrow;
    }
  }

  Future<void> updateMatchScore(int matchId, int team1Score, int team2Score) async {
    try {
      final matchIndex = _matches.indexWhere((m) => m.id == matchId);
      if (matchIndex == -1) return;
      
      final match = _matches[matchIndex];
      final updatedMatch = match.copyWith(
        team1Score: team1Score,
        team2Score: team2Score,
        status: 'in_progress',
      );
      
      // Update in Firebase
      await _firebaseService.updateMatch(updatedMatch);
      
      // Update local state
      _matches[matchIndex] = updatedMatch;
      
      // Refresh from Firebase to ensure consistency
      await fetchMatches();
      
      // Update selected match if it's the one being updated
      if (_selectedMatch != null && _selectedMatch!.id == matchId) {
        _selectedMatch = updatedMatch;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating match score: $e');
      rethrow;
    }
  }

  Future<void> completeMatch(int matchId) async {
    try {
      final matchIndex = _matches.indexWhere((m) => m.id == matchId);
      if (matchIndex == -1) return;
      
      final match = _matches[matchIndex];
      final updatedMatch = match.copyWith(
        status: 'completed',
        completedDate: DateTime.now(),
      );
      
      // Update in Firebase
      await _firebaseService.updateMatch(updatedMatch);
      
      // Update local state
      _matches[matchIndex] = updatedMatch;
      
      // Refresh from Firebase to ensure consistency
      await fetchMatches();
      
      // Update selected match if it's the one being updated
      if (_selectedMatch != null && _selectedMatch!.id == matchId) {
        _selectedMatch = updatedMatch;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error completing match: $e');
      rethrow;
    }
  }

  Future<void> deleteMatch(int matchId) async {
    try {
      await _firebaseService.deleteMatch(matchId);
      
      // Remove from local list
      _matches.removeWhere((match) => match.id == matchId);
      
      // Clear selected match if it's the one being deleted
      if (_selectedMatch != null && _selectedMatch!.id == matchId) {
        _selectedMatch = null;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting match: $e');
      rethrow;
    }
  }
}