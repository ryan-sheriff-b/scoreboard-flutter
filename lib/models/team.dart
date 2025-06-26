class Team {
  final int? id;
  final int groupId;
  final String name;
  final String description;
  final DateTime createdAt;

  Team({
    this.id,
    required this.groupId,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      groupId: map['groupId'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Team copyWith({
    int? id,
    int? groupId,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}