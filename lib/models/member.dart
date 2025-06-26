class Member {
  final int? id;
  final int teamId;
  final String name;
  final String role;
  final DateTime createdAt;

  Member({
    this.id,
    required this.teamId,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'name': name,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      teamId: map['teamId'],
      name: map['name'],
      role: map['role'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Member copyWith({
    int? id,
    int? teamId,
    String? name,
    String? role,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}