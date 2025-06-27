import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';
import '../models/match.dart';
import '../models/group.dart';
import '../models/member.dart';

class FirestoreCache {
  static final FirestoreCache _instance = FirestoreCache._internal();
  factory FirestoreCache() => _instance;
  FirestoreCache._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Team> teams = [];
  List<Match> matches = [];
  List<Group> groups = [];
  List<Member> members = [];

  Future<void> refresh() async {
    // Fetch all teams
    final teamsSnapshot = await _firestore.collection('teams').get();
    teams = teamsSnapshot.docs.map((doc) {
      final data = doc.data();
      int idValue = (data['id'] as int?) ?? doc.id.hashCode;
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
      return Team(
        id: idValue,
        groupId: data['groupId'] ?? 0,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        createdAt: createdAt,
      );
    }).toList();

    // Fetch all matches
    final matchesSnapshot = await _firestore.collection('matches').get();
    matches = matchesSnapshot.docs.map((doc) {
      final data = doc.data();
      int id = data['id'] ?? doc.id.hashCode;
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
      DateTime scheduledDate;
      if (data['scheduledDate'] is Timestamp) {
        scheduledDate = (data['scheduledDate'] as Timestamp).toDate();
      } else if (data['scheduledDate'] is String) {
        scheduledDate = DateTime.parse(data['scheduledDate']);
      } else {
        scheduledDate = DateTime.now();
      }
      DateTime? completedDate;
      if (data['completedDate'] is Timestamp) {
        completedDate = (data['completedDate'] as Timestamp).toDate();
      } else if (data['completedDate'] is String) {
        completedDate = DateTime.parse(data['completedDate']);
      } else {
        completedDate = null;
      }
      return Match(
        id: id,
        groupId: data['groupId'],
        team1Id: data['team1Id'],
        team2Id: data['team2Id'],
        team1GroupId: data['team1GroupId'],
        team2GroupId: data['team2GroupId'],
        team1Name: data['team1Name'] ?? '',
        team2Name: data['team2Name'] ?? '',
        team1Score: data['team1Score'] ?? 0,
        team2Score: data['team2Score'] ?? 0,
        status: data['status'] ?? 'scheduled',
        matchType: data['matchType'] ?? 'regular',
        scheduledDate: scheduledDate,
        completedDate: completedDate,
        createdAt: createdAt,
      );
    }).toList();

    // Fetch all groups
    final groupsSnapshot = await _firestore.collection('groups').get();
    groups = groupsSnapshot.docs.map((doc) {
      final data = doc.data();
      int idValue = (data['id'] as int?) ?? doc.id.hashCode;
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
      return Group(
        id: idValue,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        createdAt: createdAt,
      );
    }).toList();

    // Fetch all members
    final membersSnapshot = await _firestore.collection('members').get();
    members = membersSnapshot.docs.map((doc) {
      final data = doc.data();
      int idValue = (data['id'] as int?) ?? doc.id.hashCode;
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
      return Member(
        id: idValue,
        teamId: data['teamId'] ?? 0,
        name: data['name'] ?? '',
        role: data['role'] ?? '',
        createdAt: createdAt,
      );
    }).toList();
  }
}
