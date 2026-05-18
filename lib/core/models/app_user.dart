import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String? photoUrl;
  final bool isPremium;
  final bool isSuperUser;
  final int pinLimit;
  final bool chatEnabled;
  final bool chatScheduleEnabled;
  final String chatAvailableFrom;
  final String chatAvailableTo;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl,
    this.isPremium = false,
    this.isSuperUser = false,
    this.pinLimit = 5,
    this.chatEnabled = true,
    this.chatScheduleEnabled = false,
    this.chatAvailableFrom = '08:00',
    this.chatAvailableTo = '22:00',
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      isPremium: map['isPremium'] ?? false,
      isSuperUser: map['isSuperUser'] ?? false,
      pinLimit: map['pinLimit'] ?? 5,
      chatEnabled: map['chatEnabled'] ?? true,
      chatScheduleEnabled: map['chatScheduleEnabled'] ?? false,
      chatAvailableFrom: map['chatAvailableFrom'] ?? '08:00',
      chatAvailableTo: map['chatAvailableTo'] ?? '22:00',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'isPremium': isPremium,
      'isSuperUser': isSuperUser,
      'pinLimit': pinLimit,
      'chatEnabled': chatEnabled,
      'chatScheduleEnabled': chatScheduleEnabled,
      'chatAvailableFrom': chatAvailableFrom,
      'chatAvailableTo': chatAvailableTo,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? photoUrl,
    bool? isPremium,
    bool? isSuperUser,
    int? pinLimit,
    bool? chatEnabled,
    bool? chatScheduleEnabled,
    String? chatAvailableFrom,
    String? chatAvailableTo,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isPremium: isPremium ?? this.isPremium,
      isSuperUser: isSuperUser ?? this.isSuperUser,
      pinLimit: pinLimit ?? this.pinLimit,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      chatScheduleEnabled: chatScheduleEnabled ?? this.chatScheduleEnabled,
      chatAvailableFrom: chatAvailableFrom ?? this.chatAvailableFrom,
      chatAvailableTo: chatAvailableTo ?? this.chatAvailableTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
