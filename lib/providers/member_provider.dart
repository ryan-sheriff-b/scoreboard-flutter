import 'package:flutter/foundation.dart';
import '../models/member.dart';
import '../services/firebase_service.dart';

class MemberProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Member> _members = [];
  bool _isLoading = false;
  int? _currentTeamId;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;
  int? get currentTeamId => _currentTeamId;

  void setCurrentTeam(int teamId) {
    _currentTeamId = teamId;
    loadMembers(teamId);
  }

  Future<void> loadMembers(int teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _members = await _firebaseService.getMembers(teamId);
    } catch (e) {
      print('Error loading members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMember(Member member) async {
    try {
      final id = await _firebaseService.addMember(member);
      // Use hashCode for stable integer ID
      final newMember = member.copyWith(id: id.hashCode);
      _members.add(newMember);
      notifyListeners();
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  Future<void> updateMember(Member member) async {
    try {
      await _firebaseService.updateMember(member);
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _members[index] = member;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating member: $e');
    }
  }

  Future<void> deleteMember(int id) async {
    try {
      await _firebaseService.deleteMember(id);
      _members.removeWhere((member) => member.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting member: $e');
    }
  }
}