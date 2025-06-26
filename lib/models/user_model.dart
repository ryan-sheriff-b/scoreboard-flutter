import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isAdmin = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      createdAt: _parseCreatedAt(map['createdAt']),
    );
  }

  // Helper method to parse createdAt from different formats
  static DateTime _parseCreatedAt(dynamic createdAtValue) {
    if (createdAtValue is Timestamp) {
      return createdAtValue.toDate();
    } else if (createdAtValue is String) {
      return DateTime.parse(createdAtValue);
    } else {
      return DateTime.now();
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}