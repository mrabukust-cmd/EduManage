import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a document in the `users` collection.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'teacher' | 'student'
  final bool approved;
  final String photoUrl;
  final String phone;
  final String address;
  final String bio;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.approved,
    this.photoUrl = '',
    this.phone = '',
    this.address = '',
    this.bio = '',
    this.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      uid: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      approved: map['approved'] as bool? ?? false,
      photoUrl: map['photoUrl'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'approved': approved,
      'photoUrl': photoUrl,
      'phone': phone,
      'address': address,
      'bio': bio,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    bool? approved,
    String? photoUrl,
    String? phone,
    String? address,
    String? bio,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      createdAt: createdAt,
    );
  }
}