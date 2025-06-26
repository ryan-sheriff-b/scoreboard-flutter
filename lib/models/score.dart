class Score {
  final int? id;
  final int teamId;
  final int points;
  final String description;
  final DateTime createdAt;

  Score({
    this.id,
    required this.teamId,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'points': points,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      id: map['id'],
      teamId: map['teamId'],
      points: map['points'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Score copyWith({
    int? id,
    int? teamId,
    int? points,
    String? description,
    DateTime? createdAt,
  }) {
    return Score(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      points: points ?? this.points,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}