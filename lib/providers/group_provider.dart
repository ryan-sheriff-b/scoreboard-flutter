import 'package:flutter/foundation.dart';
import '../models/group.dart';
import '../services/firebase_service.dart';

class GroupProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Group> _groups = [];
  bool _isLoading = false;

  List<Group> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _groups = await _firebaseService.getGroups();
    } catch (e) {
      print('Error loading groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGroup(Group group) async {
    try {
      final id = await _firebaseService.addGroup(group);
      // Use hashCode of the string ID to create a stable integer ID
      final newGroup = group.copyWith(id: id.hashCode);
      _groups.add(newGroup);
      notifyListeners();
    } catch (e) {
      print('Error adding group: $e');
    }
  }

  Future<void> updateGroup(Group group) async {
    try {
      await _firebaseService.updateGroup(group);
      final index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _groups[index] = group;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating group: $e');
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      await _firebaseService.deleteGroup(id);
      _groups.removeWhere((group) => group.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting group: $e');
    }
  }
}