import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final List<String> members;
  final String creatorId;
  final bool isPrivate;
  final List<String> pendingMembers;
  final Timestamp createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.creatorId,
    required this.isPrivate,
    required this.pendingMembers,
    required this.createdAt,
  });

  factory Group.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      creatorId: data['creatorId'] ?? '',
      isPrivate: data['isPrivate'] ?? false,
      pendingMembers: List<String>.from(data['pendingMembers'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'members': members,
      'creatorId': creatorId,
      'isPrivate': isPrivate,
      'pendingMembers': pendingMembers,
      'createdAt': createdAt,
    };
  }

  bool isCreator(String userId) {
    return creatorId == userId;
  }

  bool isMember(String userId) {
    return members.contains(userId);
  }

  bool isPendingMember(String userId) {
    return pendingMembers.contains(userId);
  }
} 