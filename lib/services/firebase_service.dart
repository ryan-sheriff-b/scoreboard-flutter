import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/group.dart';
import '../models/team.dart';
import '../models/member.dart';
import '../models/score.dart';
import '../models/match.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  
  // Initialize Firebase Auth with persistence
  Future<void> initializeAuth() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    if (currentUser == null) {
      //print('No current user, cannot check admin status'); // Debug //print
      return false;
    }
    
    //print('Checking admin status for user: ${currentUser!.uid}'); // Debug //print
    
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        //print('User document exists for admin check'); // Debug //print
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        //print('User data for admin check: $userData'); // Debug //print
        bool isAdmin = userData['isAdmin'] ?? false;
        //print('isAdmin value from Firestore: $isAdmin'); // Debug //print
        return isAdmin;
      }
      //print('User document does not exist for admin check'); // Debug //print
      return false;
    } catch (e) {
      //print('Error checking admin status: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }

  // Create user document in Firestore after registration
  Future<void> createUserDocument(UserModel user) {
    return _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      //print('Getting user data for uid: $uid'); // Debug //print
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        //print('User document exists'); // Debug //print
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        //print('User data: $data'); // Debug //print
        //print('isAdmin in Firestore: ${data['isAdmin']}'); // Debug //print
        UserModel user = UserModel.fromMap(data);
        //print('Parsed UserModel: ${user.toMap()}'); // Debug //print
        return user;
      }
      //print('User document does not exist'); // Debug //print
      return null;
    } catch (e) {
      //print('Error getting user data: $e');
      return null;
    }
  }

  // CRUD operations for groups
  Future<String> addGroup(Group group) async {
    try {
      // Create the document first
      DocumentReference docRef = await _firestore.collection('groups').add({
        ...group.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Generate a stable integer ID from the document ID
      int idValue = docRef.id.hashCode;
      
      // Update the document with the ID
      await docRef.update({'id': idValue});
      
      return docRef.id;
    } catch (e) {
      //print('Error adding group: $e');
      throw e;
    }
  }

  Future<List<Group>> getGroups() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Use the stored ID if available, otherwise generate from document ID
        int idValue = (data['id'] as int?) ?? doc.id.hashCode;
        // Handle createdAt which could be a Timestamp or a String
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
    } catch (e) {
      //print('Error getting groups: $e');
      return [];
    }
  }

  Future<void> updateGroup(Group group) async {
    // First, try to find the document by querying for the group ID
    QuerySnapshot querySnapshot = await _firestore
        .collection('groups')
        .where('id', isEqualTo: group.id)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, update it
      return querySnapshot.docs.first.reference.update(group.toMap());
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      // This is for backward compatibility
      return _firestore.collection('groups').doc(group.id.toString()).update(group.toMap());
    }
  }

  Future<void> deleteGroup(int id) async {
    // Delete the group and all related teams, members, and scores
    WriteBatch batch = _firestore.batch();
    
    // Find the group document
    QuerySnapshot groupSnapshot = await _firestore
        .collection('groups')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    
    DocumentReference groupRef;
    if (groupSnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, use its reference
      groupRef = groupSnapshot.docs.first.reference;
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      groupRef = _firestore.collection('groups').doc(id.toString());
    }
    
    // Delete the group
    batch.delete(groupRef);
    
    // Get and delete all teams in the group
    QuerySnapshot teamsSnapshot = await _firestore
        .collection('teams')
        .where('groupId', isEqualTo: id)
        .get();
    
    for (var teamDoc in teamsSnapshot.docs) {
      batch.delete(teamDoc.reference);
      
      // Get team ID from the document data
      Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
      int teamId = (teamData['id'] as int?) ?? teamDoc.id.hashCode;
      
      // Get and delete all members in the team
      QuerySnapshot membersSnapshot = await _firestore
          .collection('members')
          .where('teamId', isEqualTo: teamId)
          .get();
      
      for (var memberDoc in membersSnapshot.docs) {
        batch.delete(memberDoc.reference);
      }
      
      // Get and delete all scores for the team
      QuerySnapshot scoresSnapshot = await _firestore
          .collection('scores')
          .where('teamId', isEqualTo: teamId)
          .get();
      
      for (var scoreDoc in scoresSnapshot.docs) {
        batch.delete(scoreDoc.reference);
      }
    }
    
    return batch.commit();
  }

  // CRUD operations for teams
  Future<String> addTeam(Team team) async {
    try {
      // Create the document first
      DocumentReference docRef = await _firestore.collection('teams').add({
        ...team.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Generate a stable integer ID from the document ID
      int idValue = docRef.id.hashCode;
      
      // Update the document with the ID
      await docRef.update({'id': idValue});
      
      return docRef.id;
    } catch (e) {
      //print('Error adding team: $e');
      throw e;
    }
  }

  Future<List<Team>> getTeams(int groupId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('teams')
          .where('groupId', isEqualTo: groupId)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Use the stored ID if available, otherwise generate from document ID
        int idValue = (data['id'] as int?) ?? doc.id.hashCode;
        // Handle createdAt which could be a Timestamp or a String
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
    } catch (e) {
      //print('Error getting teams: $e');
      return [];
    }
  }

  Future<void> updateTeam(Team team) async {
    // First, try to find the document by querying for the team ID
    QuerySnapshot querySnapshot = await _firestore
        .collection('teams')
        .where('id', isEqualTo: team.id)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, update it
      return querySnapshot.docs.first.reference.update(team.toMap());
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      // This is for backward compatibility
      return _firestore.collection('teams').doc(team.id.toString()).update(team.toMap());
    }
  }

  Future<void> deleteTeam(int id) async {
    // Delete the team and all related members and scores
    WriteBatch batch = _firestore.batch();
    
    // Find the team document
    QuerySnapshot teamSnapshot = await _firestore
        .collection('teams')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    
    DocumentReference teamRef;
    if (teamSnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, use its reference
      teamRef = teamSnapshot.docs.first.reference;
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      teamRef = _firestore.collection('teams').doc(id.toString());
    }
    
    // Delete the team
    batch.delete(teamRef);
    
    // Get and delete all members in the team
    QuerySnapshot membersSnapshot = await _firestore
        .collection('members')
        .where('teamId', isEqualTo: id)
        .get();
    
    for (var doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Get and delete all scores for the team
    QuerySnapshot scoresSnapshot = await _firestore
        .collection('scores')
        .where('teamId', isEqualTo: id)
        .get();
    
    for (var doc in scoresSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    return batch.commit();
  }

  // CRUD operations for members
  Future<String> addMember(Member member) async {
    try {
      // Create the document first
      DocumentReference docRef = await _firestore.collection('members').add({
        ...member.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Generate a stable integer ID from the document ID
      int idValue = docRef.id.hashCode;
      
      // Update the document with the ID
      await docRef.update({'id': idValue});
      
      return docRef.id;
    } catch (e) {
      //print('Error adding member: $e');
      throw e;
    }
  }

  Future<List<Member>> getMembers(int teamId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('members')
          .where('teamId', isEqualTo: teamId)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Use the stored ID if available, otherwise generate from document ID
        int idValue = (data['id'] as int?) ?? doc.id.hashCode;
        // Handle createdAt which could be a Timestamp or a String
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
    } catch (e) {
      //print('Error getting members: $e');
      return [];
    }
  }

  Future<void> updateMember(Member member) async {
    // First, try to find the document by querying for the member ID
    QuerySnapshot querySnapshot = await _firestore
        .collection('members')
        .where('id', isEqualTo: member.id)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, update it
      return querySnapshot.docs.first.reference.update(member.toMap());
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      // This is for backward compatibility
      return _firestore.collection('members').doc(member.id.toString()).update(member.toMap());
    }
  }

  Future<void> deleteMember(int id) async {
    // Find the member document
    QuerySnapshot memberSnapshot = await _firestore
        .collection('members')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    
    if (memberSnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, delete it
      return memberSnapshot.docs.first.reference.delete();
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      return _firestore.collection('members').doc(id.toString()).delete();
    }
  }

  // CRUD operations for scores
  Future<String> addScore(Score score) async {
    try {
      // Create the document first
      DocumentReference docRef = await _firestore.collection('scores').add({
        ...score.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Generate a stable integer ID from the document ID
      int idValue = docRef.id.hashCode;
      
      // Update the document with the ID
      await docRef.update({'id': idValue});
      
      return docRef.id;
    } catch (e) {
      //print('Error adding score: $e');
      throw e;
    }
  }

  Future<List<Score>> getScores(int teamId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('scores')
          .where('teamId', isEqualTo: teamId)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Use the stored ID if available, otherwise generate from document ID
        int idValue = (data['id'] as int?) ?? doc.id.hashCode;
        // Handle createdAt which could be a Timestamp or a String
        DateTime createdAt;
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAt = DateTime.parse(data['createdAt']);
        } else {
          createdAt = DateTime.now();
        }
        
        return Score(
          id: idValue,
          teamId: data['teamId'] ?? 0,
          points: data['points'] ?? 0,
          description: data['description'] ?? '',
          createdAt: createdAt,
        );
      }).toList();
    } catch (e) {
      //print('Error getting scores: $e');
      return [];
    }
  }

  Future<void> updateScore(Score score) async {
    // First, try to find the document by querying for the score ID
    QuerySnapshot querySnapshot = await _firestore
        .collection('scores')
        .where('id', isEqualTo: score.id)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, update it
      return querySnapshot.docs.first.reference.update(score.toMap());
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      // This is for backward compatibility
      return _firestore.collection('scores').doc(score.id.toString()).update(score.toMap());
    }
  }

  Future<void> deleteScore(int id) async {
    // Find the score document
    QuerySnapshot scoreSnapshot = await _firestore
        .collection('scores')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    
    if (scoreSnapshot.docs.isNotEmpty) {
      // If we found the document by ID field, delete it
      return scoreSnapshot.docs.first.reference.delete();
    } else {
      // If we couldn't find it by ID field, try using the ID as document ID
      return _firestore.collection('scores').doc(id.toString()).delete();
    }
  }

  // Get team total score
  Future<int> getTeamTotalScore(int teamId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('scores')
          .where('teamId', isEqualTo: teamId)
          .get();
      
      int totalScore = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalScore += data['points'] as int;
      }
      
      return totalScore;
    } catch (e) {
      //print('Error getting team total score: $e');
      return 0;
    }
  }

//   // Get teams with scores ordered by score
// Future<List<Map<String, dynamic>>> getTeamsWithScores(int groupId) async {
//   try {
//     // Step 1: Get all teams in the group
//     QuerySnapshot teamsSnapshot = await _firestore
//         .collection('teams')
//         .where('groupId', isEqualTo: groupId)
//         .get();

//     // Step 2: Get all completed matches involving these teams
//     QuerySnapshot matchesSnapshot = await _firestore
//         .collection('matches')
//         .where('status', isEqualTo: 'completed')
//         .get();

//     List<Match> allMatches = _parseMatchesFromSnapshot(matchesSnapshot);
//     List<Map<String, dynamic>> teamsWithScores = [];

//     // Step 3: Build maps for scores
//     Map<int, int> teamGoalsScored = {};
//     Map<int, int> teamWins = {};
//     Map<int, int> teamLosses = {};
//     Map<int, int> teamDraws = {};
//     Map<int, int> teamTotalMatches = {};

//     // Step 4: Process each match
//     for (var match in allMatches) {
//       // Only consider matches where either team belongs to the group
//       bool isGroupMatch = match.team1GroupId == groupId || match.team2GroupId == groupId;
//       if (!isGroupMatch) continue;

//       teamTotalMatches[match.team1Id] = (teamTotalMatches[match.team1Id] ?? 0) + 1;
//       teamTotalMatches[match.team2Id] = (teamTotalMatches[match.team2Id] ?? 0) + 1;

//       teamGoalsScored[match.team1Id] = (teamGoalsScored[match.team1Id] ?? 0) + match.team1Score;
//       teamGoalsScored[match.team2Id] = (teamGoalsScored[match.team2Id] ?? 0) + match.team2Score;

//       if (match.team1Score > match.team2Score) {
//         teamWins[match.team1Id] = (teamWins[match.team1Id] ?? 0) + 1;
//         teamLosses[match.team2Id] = (teamLosses[match.team2Id] ?? 0) + 1;
//       } else if (match.team2Score > match.team1Score) {
//         teamWins[match.team2Id] = (teamWins[match.team2Id] ?? 0) + 1;
//         teamLosses[match.team1Id] = (teamLosses[match.team1Id] ?? 0) + 1;
//       } else {
//         teamDraws[match.team1Id] = (teamDraws[match.team1Id] ?? 0) + 1;
//         teamDraws[match.team2Id] = (teamDraws[match.team2Id] ?? 0) + 1;
//       }
//     }

//     // Step 5: Build leaderboard data
//     for (var teamDoc in teamsSnapshot.docs) {
//       Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
//       int teamId = (teamData['id'] as int?) ?? teamDoc.id.hashCode;

//       int totalScore = teamGoalsScored[teamId] ?? 0;

//       // Get members
//       QuerySnapshot membersSnapshot = await _firestore
//           .collection('members')
//           .where('teamId', isEqualTo: teamId)
//           .get();

//       List<Map<String, dynamic>> members = membersSnapshot.docs.map((memberDoc) {
//         Map<String, dynamic> memberData = memberDoc.data() as Map<String, dynamic>;
//         return {
//           'name': memberData['name'] ?? '',
//           'role': memberData['role'] ?? '',
//         };
//       }).toList();

//       teamsWithScores.add({
//         'id': teamId,
//         'name': teamData['name'] ?? '',
//         'description': teamData['description'] ?? '',
//         'groupId': groupId,
//         'totalScore': totalScore,
//         'wins': teamWins[teamId] ?? 0,
//         'losses': teamLosses[teamId] ?? 0,
//         'draws': teamDraws[teamId] ?? 0,
//         'totalMatches': teamTotalMatches[teamId] ?? 0,
//         'members': members,
//       });
//     }

//     // Step 6: Sort by totalScore (goals scored)
//     teamsWithScores.sort((a, b) => b['totalScore'].compareTo(a['totalScore']));
//     return teamsWithScores;
//   } catch (e) {
//     //print('Error getting teams with scores: $e');
//     return [];
//   }
// }


  // Get all teams with scores across all groups (for global leaderboard)
Future<List<Map<String, dynamic>>> getAllTeamsWithScores({int? groupId}) async {
  try {
    //print('DEBUG: Getting all teams with scores from matches');

    // Fetch teams, filtered by groupId if provided
    Query teamsQuery = _firestore.collection('teams');
    if (groupId != null) {
      teamsQuery = teamsQuery.where('groupId', isEqualTo: groupId);
    }
    QuerySnapshot teamsSnapshot = await teamsQuery.get();
    List<Map<String, dynamic>> teamsWithScores = [];

    // Fetch ALL matches (any status)
    QuerySnapshot matchesSnapshot = await _firestore.collection('matches').get();
    List<Match> allMatches = _parseMatchesFromSnapshot(matchesSnapshot);
    //print('DEBUG: Found ${allMatches.length} total matches');

    // Initialize stats maps
    Map<int, int> teamGoalsScored = {};
    Map<int, int> teamMatchPoints = {};
    Map<int, int> teamWins = {};
    Map<int, int> teamLosses = {};
    Map<int, int> teamDraws = {};
    Map<int, int> teamTotalMatches = {};
    Map<int, int> teamCompletedMatches = {};

    for (var match in allMatches) {
      // Count all matches
      teamTotalMatches[match.team1Id] = (teamTotalMatches[match.team1Id] ?? 0) + 1;
      teamTotalMatches[match.team2Id] = (teamTotalMatches[match.team2Id] ?? 0) + 1;

      if (match.status != 'completed') continue;

      // Count completed matches
      teamCompletedMatches[match.team1Id] = (teamCompletedMatches[match.team1Id] ?? 0) + 1;
      teamCompletedMatches[match.team2Id] = (teamCompletedMatches[match.team2Id] ?? 0) + 1;

      // Goals scored
      teamGoalsScored[match.team1Id] = (teamGoalsScored[match.team1Id] ?? 0) + match.team1Score;
      teamGoalsScored[match.team2Id] = (teamGoalsScored[match.team2Id] ?? 0) + match.team2Score;

      // Match result logic
      if (match.team1Score > match.team2Score) {
        teamMatchPoints[match.team1Id] = (teamMatchPoints[match.team1Id] ?? 0) + 3;
        teamWins[match.team1Id] = (teamWins[match.team1Id] ?? 0) + 1;
        teamLosses[match.team2Id] = (teamLosses[match.team2Id] ?? 0) + 1;
      } else if (match.team2Score > match.team1Score) {
        teamMatchPoints[match.team2Id] = (teamMatchPoints[match.team2Id] ?? 0) + 3;
        teamWins[match.team2Id] = (teamWins[match.team2Id] ?? 0) + 1;
        teamLosses[match.team1Id] = (teamLosses[match.team1Id] ?? 0) + 1;
      } else {
        teamMatchPoints[match.team1Id] = (teamMatchPoints[match.team1Id] ?? 0) + 1;
        teamMatchPoints[match.team2Id] = (teamMatchPoints[match.team2Id] ?? 0) + 1;
        teamDraws[match.team1Id] = (teamDraws[match.team1Id] ?? 0) + 1;
        teamDraws[match.team2Id] = (teamDraws[match.team2Id] ?? 0) + 1;
      }
    }

    for (var teamDoc in teamsSnapshot.docs) {
      Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
      int teamId = (teamData['id'] as int?) ?? teamDoc.id.hashCode;
      int groupIdValue = (teamData['groupId'] as int?) ?? 0;

      // Get group name
      String groupName = '';
      if (groupIdValue > 0) {
        QuerySnapshot groupSnapshot = await _firestore
            .collection('groups')
            .where('id', isEqualTo: groupIdValue)
            .limit(1)
            .get();

        if (groupSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> groupData = groupSnapshot.docs.first.data() as Map<String, dynamic>;
          groupName = groupData['name'] ?? '';
        } else {
          DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupIdValue.toString()).get();
          if (groupDoc.exists) {
            Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
            groupName = groupData['name'] ?? '';
          }
        }
      }

      // Stats
      int matchScore = teamMatchPoints[teamId] ?? 0;
      int totalScore = teamGoalsScored[teamId] ?? 0;
      int totalMatches = teamTotalMatches[teamId] ?? 0;
      int completedMatches = teamCompletedMatches[teamId] ?? 0;

      // Members
      QuerySnapshot membersSnapshot = await _firestore
          .collection('members')
          .where('teamId', isEqualTo: teamId)
          .get();

      List<Map<String, dynamic>> members = membersSnapshot.docs.map((memberDoc) {
        Map<String, dynamic> memberData = memberDoc.data() as Map<String, dynamic>;
        return {
          'name': memberData['name'] ?? '',
          'role': memberData['role'] ?? '',
        };
      }).toList();

      teamsWithScores.add({
        'id': teamId,
        'name': teamData['name'] ?? '',
        'description': teamData['description'] ?? '',
        'groupId': groupIdValue,
        'groupName': groupName,
        'matchScore': matchScore,
        'totalScore': totalScore,
        'wins': teamWins[teamId] ?? 0,
        'losses': teamLosses[teamId] ?? 0,
        'draws': teamDraws[teamId] ?? 0,
        'totalMatches': totalMatches,
        'completedMatches': completedMatches,
        'members': members,
      });
    }

    // Sort by total goals scored
    teamsWithScores.sort((a, b) => b['totalScore'].compareTo(a['totalScore']));

    return teamsWithScores;
  } catch (e) {
    //print('Error getting teams with scores: $e');
    return [];
  }
}


  // Helper method to generate a stable integer ID from a document ID
  int _generateIdFromDocId(String docId) {
    return docId.hashCode;
  }

  // Match related methods
  Future<List<Match>> getMatches(int groupId) async {
    try {
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('groupId', isEqualTo: groupId)
          .orderBy('scheduledDate', descending: false)
          .get();

      return _parseMatchesFromSnapshot(matchesSnapshot);
    } catch (e) {
      //print('Error getting matches: $e');
      return [];
    }
  }
  
  // Get all matches globally
  Future<List<Match>> getAllMatches({bool completedOnly = false}) async {
    try {
      Query query = _firestore.collection('matches');
      
      // Filter for completed matches only if requested
      if (completedOnly) {
        query = query.where('status', isEqualTo: 'completed');
      }
      
      // Order by scheduled date, most recent first
      final matchesSnapshot = await query
          .orderBy('scheduledDate', descending: true)
          .get();

      return _parseMatchesFromSnapshot(matchesSnapshot);
    } catch (e) {
      //print('Error getting all matches: $e');
      return [];
    }
  }
    
  // Get matches for a specific team
  Future<List<Match>> getMatchesByTeamId(int teamId) async {
    //print('DEBUG: Firebase - Getting matches for team $teamId');
    try {
      // We need to query for matches where the team is either team1 or team2
      //print('DEBUG: Firebase - Querying for team1 matches');
      final team1MatchesSnapshot = await _firestore
          .collection('matches')
          .where('team1Id', isEqualTo: teamId)
          .orderBy('scheduledDate', descending: true)
          .get();
      //print('DEBUG: Firebase - Found ${team1MatchesSnapshot.docs.length} team1 matches');
          
      //print('DEBUG: Firebase - Querying for team2 matches');
      final team2MatchesSnapshot = await _firestore
          .collection('matches')
          .where('team2Id', isEqualTo: teamId)
          .orderBy('scheduledDate', descending: true)
          .get();
      //print('DEBUG: Firebase - Found ${team2MatchesSnapshot.docs.length} team2 matches');
      
      // Parse both sets of matches
      List<Match> team1Matches = _parseMatchesFromSnapshot(team1MatchesSnapshot);
      List<Match> team2Matches = _parseMatchesFromSnapshot(team2MatchesSnapshot);
      
      //print('DEBUG: Firebase - Parsed ${team1Matches.length} team1 matches and ${team2Matches.length} team2 matches');
      
      // Combine the matches
      List<Match> allTeamMatches = [...team1Matches, ...team2Matches];
      
      // Sort by scheduled date (most recent first)
      allTeamMatches.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      
      //print('DEBUG: Firebase - Returning ${allTeamMatches.length} total matches for team $teamId');
      return allTeamMatches;
    } catch (e) {
      //print('ERROR: Firebase - Error getting matches for team $teamId: $e');
      return [];
    }
  }
  
  // Get only inter-group matches (matches between teams from different groups)
  Future<List<Match>> getInterGroupMatches({bool completedOnly = false}) async {
    try {
      //print('DEBUG: Fetching inter-group matches, completedOnly=$completedOnly');
      Query query = _firestore.collection('matches');
      
      // Filter for completed matches only if requested
      if (completedOnly) {
        query = query.where('status', isEqualTo: 'completed');
      }
      
      // We can't directly query for team1GroupId != team2GroupId in Firestore,
      // so we'll fetch all matches and filter client-side
      final matchesSnapshot = await query
          .orderBy('scheduledDate', descending: true)
          .get();
      
      //print('DEBUG: Total matches fetched from Firestore: ${matchesSnapshot.docs.length}');
      
      // Debug: //print raw data from Firestore
      for (var doc in matchesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        //print('DEBUG: Raw match data - ID: ${doc.id}, groupId: ${data['groupId']}, team1GroupId: ${data['team1GroupId']}, team2GroupId: ${data['team2GroupId']}');
      }
      
      // Parse all matches
      List<Match> allMatches = _parseMatchesFromSnapshot(matchesSnapshot);
      
      //print('DEBUG: Total matches after parsing: ${allMatches.length}');
      
      // Debug: //print all matches with their group IDs
      for (var match in allMatches) {
        //print('DEBUG: Match ID: ${match.id}, groupId: ${match.groupId}, team1GroupId: ${match.team1GroupId}, team2GroupId: ${match.team2GroupId}, team1Name: ${match.team1Name}, team2Name: ${match.team2Name}');
      }
      
      // Filter for inter-group matches
      final interGroupMatches = allMatches.where((match) => 
        match.team1GroupId != null && 
        match.team2GroupId != null && 
        match.team1GroupId != match.team2GroupId
      ).toList();
      
      //print('DEBUG: Inter-group matches found: ${interGroupMatches.length}');
      
      // Debug: //print details of each inter-group match found
      for (var match in interGroupMatches) {
        //print('DEBUG: Inter-group match - ID: ${match.id}, groupId: ${match.groupId}, team1GroupId: ${match.team1GroupId}, team2GroupId: ${match.team2GroupId}, team1Name: ${match.team1Name}, team2Name: ${match.team2Name}');
      }
      
      return interGroupMatches;
    } catch (e) {
      //print('Error getting inter-group matches: $e');
      return [];
    }
  }
  
  // Helper method to parse matches from a query snapshot
  List<Match> _parseMatchesFromSnapshot(QuerySnapshot matchesSnapshot) {
    return matchesSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Handle id (either stored or generated from document ID)
      int id = data['id'] ?? _generateIdFromDocId(doc.id);
      
      // Debug: //print raw data for this document
      //print('DEBUG: Parsing match - Doc ID: ${doc.id}, Data: $data');
      //print('DEBUG: Parsing match - team1GroupId: ${data['team1GroupId']}, team2GroupId: ${data['team2GroupId']}');
      
      // Handle createdAt (can be Timestamp or String)
      DateTime createdAt;
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        createdAt = DateTime.parse(data['createdAt']);
      } else {
        createdAt = DateTime.now();
      }
      
      // Handle scheduledDate (can be Timestamp or String)
      DateTime scheduledDate;
      if (data['scheduledDate'] is Timestamp) {
        scheduledDate = (data['scheduledDate'] as Timestamp).toDate();
      } else if (data['scheduledDate'] is String) {
        scheduledDate = DateTime.parse(data['scheduledDate']);
      } else {
        scheduledDate = DateTime.now();
      }
      
      // Handle completedDate (can be Timestamp, String, or null)
      DateTime? completedDate;
      if (data['completedDate'] is Timestamp) {
        completedDate = (data['completedDate'] as Timestamp).toDate();
      } else if (data['completedDate'] is String) {
        completedDate = DateTime.parse(data['completedDate']);
      } else {
        completedDate = null;
      }
      
      // Extract group IDs with null checking
      final team1GroupId = data['team1GroupId'];
      final team2GroupId = data['team2GroupId'];
      
      final match = Match(
        id: id,
        groupId: data['groupId'],
        team1Id: data['team1Id'],
        team2Id: data['team2Id'],
        team1GroupId: team1GroupId,
        team2GroupId: team2GroupId,
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
      
      // Debug: //print created match object
      //print('DEBUG: Created Match object - ID: ${match.id}, groupId: ${match.groupId}, team1GroupId: ${match.team1GroupId}, team2GroupId: ${match.team2GroupId}');
      
      return match;
    }).toList();
  }

  Future<void> addMatch(Match match) async {
    try {
      //print('DEBUG: Adding match - groupId: ${match.groupId}, team1GroupId: ${match.team1GroupId}, team2GroupId: ${match.team2GroupId}');
      //print('DEBUG: Match details - team1Name: ${match.team1Name}, team2Name: ${match.team2Name}');
      
      // Create the match data map with all fields
      final Map<String, dynamic> matchData = {
        'groupId': match.groupId,
        'team1Id': match.team1Id,
        'team2Id': match.team2Id,
        'team1GroupId': match.team1GroupId,
        'team2GroupId': match.team2GroupId,
        'team1Name': match.team1Name,
        'team2Name': match.team2Name,
        'team1Score': match.team1Score,
        'team2Score': match.team2Score,
        'status': match.status,
        'matchType': match.matchType,
        'scheduledDate': Timestamp.fromDate(match.scheduledDate),
        'completedDate': match.completedDate != null ? Timestamp.fromDate(match.completedDate!) : null,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      //print('DEBUG: Match data being saved to Firestore: $matchData');
      
      final docRef = await _firestore.collection('matches').add(matchData);
      
      // Update the document with an integer ID
      final id = _generateIdFromDocId(docRef.id);
      await docRef.update({'id': id});
      
      //print('DEBUG: Match added successfully with ID: $id');
      
      // Verify the match was saved correctly
      final savedDoc = await _firestore.collection('matches').doc(docRef.id).get();
      final savedData = savedDoc.data() as Map<String, dynamic>;
      //print('DEBUG: Saved match data from Firestore: $savedData');
      //print('DEBUG: Saved team1GroupId: ${savedData['team1GroupId']}, team2GroupId: ${savedData['team2GroupId']}');
    } catch (e) {
      //print('Error adding match: $e');
      rethrow;
    }
  }

  Future<void> updateMatch(Match match) async {
    try {
      if (match.id == null) {
        throw Exception('Match ID cannot be null for update operation');
      }
      
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('id', isEqualTo: match.id)
          .get();
      
      if (matchesSnapshot.docs.isEmpty) {
        throw Exception('Match not found with ID: ${match.id}');
      }
      
      // Get the original match to compare scores
      final originalMatchData = matchesSnapshot.docs.first.data() as Map<String, dynamic>;
      final int originalTeam1Score = originalMatchData['team1Score'] ?? 0;
      final int originalTeam2Score = originalMatchData['team2Score'] ?? 0;
      
      // Calculate score differences
      final int team1ScoreDiff = match.team1Score - originalTeam1Score;
      final int team2ScoreDiff = match.team2Score - originalTeam2Score;
      
      // Update the match document with all fields to ensure consistency
      final docId = matchesSnapshot.docs.first.id;
      await _firestore.collection('matches').doc(docId).update({
        'team1Score': match.team1Score,
        'team2Score': match.team2Score,
        'status': match.status,
        'matchType': match.matchType,
        'completedDate': match.completedDate != null ? Timestamp.fromDate(match.completedDate!) : null,
        'team1Name': match.team1Name,
        'team2Name': match.team2Name,
        'team1GroupId': match.team1GroupId,
        'team2GroupId': match.team2GroupId,
        'scheduledDate': Timestamp.fromDate(match.scheduledDate),
      });
      
      // If scores have changed, add entries to the scores collection
      if (team1ScoreDiff != 0) {
        await addScore(Score(
          teamId: match.team1Id,
          points: team1ScoreDiff,
          description: 'Match score update: ${match.team1Name} vs ${match.team2Name}',
          createdAt: DateTime.now(),
        ));
      }
      
      if (team2ScoreDiff != 0) {
        await addScore(Score(
          teamId: match.team2Id,
          points: team2ScoreDiff,
          description: 'Match score update: ${match.team2Name} vs ${match.team1Name}',
          createdAt: DateTime.now(),
        ));
      }
      
      // If match is being completed, add a completion note to the scores
      if (match.status == 'completed' && originalMatchData['status'] != 'completed') {
        // Determine winner or if it's a tie
        String team1Result = '';
        String team2Result = '';
        
        if (match.team1Score > match.team2Score) {
          team1Result = 'Win';
          team2Result = 'Loss';
        } else if (match.team1Score < match.team2Score) {
          team1Result = 'Loss';
          team2Result = 'Win';
        } else {
          team1Result = 'Draw';
          team2Result = 'Draw';
        }
        
        // Add completion notes to scores
        await addScore(Score(
          teamId: match.team1Id,
          points: 0, // No additional points, just a note
          description: 'Match completed: ${team1Result} against ${match.team2Name} (${match.team1Score}-${match.team2Score})',
          createdAt: DateTime.now(),
        ));
        
        await addScore(Score(
          teamId: match.team2Id,
          points: 0, // No additional points, just a note
          description: 'Match completed: ${team2Result} against ${match.team1Name} (${match.team2Score}-${match.team1Score})',
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      //print('Error updating match: $e');
      rethrow;
    }
  }

  Future<void> deleteMatch(int matchId) async {
    try {
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('id', isEqualTo: matchId)
          .get();
      
      if (matchesSnapshot.docs.isEmpty) {
        throw Exception('Match not found with ID: $matchId');
      }
      
      final docId = matchesSnapshot.docs.first.id;
      await _firestore.collection('matches').doc(docId).delete();
    } catch (e) {
      //print('Error deleting match: $e');
      rethrow;
    }
  }
  
  // Stream of matches for real-time updates
  Stream<List<Match>> matchesStream({bool completedOnly = false}) {
    Query query = _firestore.collection('matches');
    
    if (completedOnly) {
      query = query.where('status', isEqualTo: 'completed');
    }
    
    return query.snapshots().map((snapshot) {
      return _parseMatchesFromSnapshot(snapshot);
    });
  }
  
  // Stream for a specific match by ID
  Stream<Match?> matchStream(int matchId) {
    return _firestore
        .collection('matches')
        .where('id', isEqualTo: matchId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          return _parseMatchesFromSnapshot(snapshot).first;
        });
  }
}