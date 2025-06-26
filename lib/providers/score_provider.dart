import 'package:flutter/foundation.dart';
import '../models/score.dart';
import '../services/firebase_service.dart';

class ScoreProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Score> _scores = [];
  bool _isLoading = false;
  int? _currentTeamId;
  int _totalScore = 0;

  List<Score> get scores => _scores;
  bool get isLoading => _isLoading;
  int? get currentTeamId => _currentTeamId;
  int get totalScore => _totalScore;

  void setCurrentTeam(int teamId) {
    _currentTeamId = teamId;
    loadScores(teamId);
  }

  Future<void> loadScores(int teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _scores = await _firebaseService.getScores(teamId);
      _totalScore = await _firebaseService.getTeamTotalScore(teamId);
    } catch (e) {
      print('Error loading scores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addScore(Score score) async {
    try {
      final id = await _firebaseService.addScore(score);
      // Use hashCode for stable integer ID
      final newScore = score.copyWith(id: id.hashCode);
      _scores.add(newScore);
      _totalScore += score.points;
      notifyListeners();
    } catch (e) {
      print('Error adding score: $e');
    }
  }

  Future<void> updateScore(Score score) async {
    try {
      await _firebaseService.updateScore(score);
      final index = _scores.indexWhere((s) => s.id == score.id);
      if (index != -1) {
        final oldPoints = _scores[index].points;
        _scores[index] = score;
        _totalScore = _totalScore - oldPoints + score.points;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating score: $e');
    }
  }

  Future<void> deleteScore(int id) async {
    try {
      final scoreToDelete = _scores.firstWhere((score) => score.id == id);
      await _firebaseService.deleteScore(id);
      _scores.removeWhere((score) => score.id == id);
      _totalScore -= scoreToDelete.points;
      notifyListeners();
    } catch (e) {
      print('Error deleting score: $e');
    }
  }
}