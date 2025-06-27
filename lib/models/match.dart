class Match {
  final int? id;
  final int groupId;
  final int team1Id;
  final int team2Id;
  final int? team1GroupId; // Group ID for team 1 (for inter-group matches)
  final int? team2GroupId; // Group ID for team 2 (for inter-group matches)
  final String team1Name; // For display purposes
  final String team2Name; // For display purposes
  final int team1Score;
  final int team2Score;
  final String status; // 'scheduled', 'in_progress', 'completed'
  final String? matchType; // 'regular', 'qualifier', 'eliminator', 'final'
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final DateTime createdAt;
  
  // Factory method to create an empty match object for placeholder purposes
  factory Match.empty() {
    return Match(
      id: -1,
      groupId: -1,
      team1Id: -1,
      team2Id: -1,
      team1Name: 'No matches',
      team2Name: '',
      status: 'none',
      scheduledDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  Match({
    this.id,
    required this.groupId,
    required this.team1Id,
    required this.team2Id,
    this.team1GroupId,
    this.team2GroupId,
    required this.team1Name,
    required this.team2Name,
    this.team1Score = 0,
    this.team2Score = 0,
    required this.status,
    this.matchType = 'regular',
    required this.scheduledDate,
    this.completedDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'team1Id': team1Id,
      'team2Id': team2Id,
      'team1GroupId': team1GroupId,
      'team2GroupId': team2GroupId,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'status': status,
      'matchType': matchType,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'],
      groupId: map['groupId'],
      team1Id: map['team1Id'],
      team2Id: map['team2Id'],
      team1GroupId: map['team1GroupId'],
      team2GroupId: map['team2GroupId'],
      team1Name: map['team1Name'] ?? '',
      team2Name: map['team2Name'] ?? '',
      team1Score: map['team1Score'] ?? 0,
      team2Score: map['team2Score'] ?? 0,
      status: map['status'] ?? 'scheduled',
      matchType: map['matchType'] ?? 'regular',
      scheduledDate: DateTime.parse(map['scheduledDate']),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Match copyWith({
    int? id,
    int? groupId,
    int? team1Id,
    int? team2Id,
    int? team1GroupId,
    int? team2GroupId,
    String? team1Name,
    String? team2Name,
    int? team1Score,
    int? team2Score,
    String? status,
    String? matchType,
    DateTime? scheduledDate,
    DateTime? completedDate,
    DateTime? createdAt,
  }) {
    return Match(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1GroupId: team1GroupId ?? this.team1GroupId,
      team2GroupId: team2GroupId ?? this.team2GroupId,
      team1Name: team1Name ?? this.team1Name,
      team2Name: team2Name ?? this.team2Name,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      status: status ?? this.status,
      matchType: matchType ?? this.matchType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}