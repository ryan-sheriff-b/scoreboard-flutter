import 'dart:async';
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
  
  // Stream subscription for real-time updates
  Stream<List<Match>>? _matchesStream;
  StreamSubscription<List<Match>>? _matchesSubscription;
  
  // Cache for team members
  final Map<int, List<Member>> _teamMembersCache = {};

  List<Match> get allMatches => _allMatches;
  bool get isLoading => _isLoading;
  bool get showCompletedOnly => _showCompletedOnly;
  
  // Constructor to initialize the stream
  GlobalMatchProvider() {
    _setupMatchesStream();
  }
  
  // Dispose method to clean up resources
  @override
  void dispose() {
    _cancelMatchesSubscription();
    super.dispose();
  }

  // Toggle between showing all matches or completed matches only
  void toggleCompletedOnly() {
    _showCompletedOnly = !_showCompletedOnly;
    // Cancel existing subscription
    _cancelMatchesSubscription();
    // Set up new stream with updated filter
    _setupMatchesStream();
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

  // Set up real-time stream for matches
  void _setupMatchesStream() {
    _isLoading = true;
    notifyListeners();
    
    // Get the stream from FirebaseService
    _matchesStream = _firebaseService.matchesStream(completedOnly: _showCompletedOnly);
    
    // Subscribe to the stream
    _matchesSubscription = _matchesStream?.listen((matches) {
      _allMatches = matches;
      
      // Sort matches by scheduledDate (most recent first)
      _allMatches.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print('Error in matches stream: $error');
      _isLoading = false;
      notifyListeners();
    });
  }
  
  // Cancel the stream subscription
  void _cancelMatchesSubscription() {
    _matchesSubscription?.cancel();
    _matchesSubscription = null;
    _matchesStream = null;
  }
  
  // Fetch all matches from Firebase (one-time fetch, used as fallback)
  Future<void> fetchAllMatches() async {
    // If we're already using a stream, no need to fetch
    if (_matchesSubscription != null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _allMatches = await _firebaseService.getAllMatches(completedOnly: _showCompletedOnly);
      
      // Sort matches by scheduledDate (most recent first)
      _allMatches.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      
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
      
      // Sort matches by scheduledDate (most recent first)
      _allMatches.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      
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

  // Update a match
  Future<void> updateMatch(Match updatedMatch) async {
    try {
      // Update in Firebase
      await _firebaseService.updateMatch(updatedMatch);
      
      // With real-time updates, the stream will automatically update the UI
      // But we still update the local state for immediate feedback
      final matchIndex = _allMatches.indexWhere((m) => m.id == updatedMatch.id);
      if (matchIndex != -1) {
        _allMatches[matchIndex] = updatedMatch;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating match: $e');
      rethrow;
    }
  }
}