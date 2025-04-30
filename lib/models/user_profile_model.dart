import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String gender;
  final String phone;
  final DateTime? birthDate;
  final String? photoUrl;
  final String role;
  final DateTime? createdAt;
  final String provider; // 'email', 'google', etc.

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.gender,
    required this.phone,
    this.birthDate,
    this.photoUrl,
    required this.role,
    this.createdAt,
    required this.provider,
  });

  // Factory constructor to create a UserProfile from a Map (Firebase data)
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      gender: data['gender'] ?? '',
      phone: data['phone'] ?? '',
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] is Timestamp 
              ? (data['birthDate'] as Timestamp).toDate() 
              : DateTime.parse(data['birthDate']))
          : null,
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'buyer',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] is Timestamp 
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.parse(data['created_at'])) 
          : null,
      provider: data['provider'] ?? 'email',
    );
  }

  // Method to convert UserProfile to Map (for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'gender': gender,
      'phone': phone,
      'birthDate': birthDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'role': role,
      // Let Firebase set the timestamp
      // 'created_at': createdAt?.toIso8601String(),
      'provider': provider,
    };
  }

  // Method to check if profile is complete with required fields
  bool isComplete() {
    return fullName.isNotEmpty && 
           gender.isNotEmpty && 
           phone.isNotEmpty;
  }
  
  // Create a copy of this UserProfile with modified fields
  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? gender,
    String? phone,
    DateTime? birthDate,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    String? provider,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      provider: provider ?? this.provider,
    );
  }
}