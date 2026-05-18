import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter for current Firebase User
  User? get currentFirebaseUser => _auth.currentUser;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get full AppUser model from Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  Future<AppUser?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  Future<AppUser> updateUserChatSettings({
    required String userId,
    required bool chatEnabled,
    required bool chatScheduleEnabled,
    required String chatAvailableFrom,
    required String chatAvailableTo,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);

    await userRef.update({
      'chatEnabled': chatEnabled,
      'chatScheduleEnabled': chatScheduleEnabled,
      'chatAvailableFrom': chatAvailableFrom,
      'chatAvailableTo': chatAvailableTo,
    });

    final updatedDoc = await userRef.get();
    if (updatedDoc.exists && updatedDoc.data() != null) {
      return AppUser.fromMap(updatedDoc.data()!);
    }

    throw Exception('Unable to update chat privacy settings.');
  }

  bool canReceiveChat(AppUser owner) {
    if (!owner.chatEnabled) {
      return false;
    }
    if (!owner.chatScheduleEnabled) {
      return true;
    }
    return _isWithinSchedule(owner.chatAvailableFrom, owner.chatAvailableTo);
  }

  Future<bool> canOpenChatWithUser(String ownerId) async {
    final owner = await getUserById(ownerId);
    if (owner == null) return false;
    return canReceiveChat(owner);
  }

  bool _isWithinSchedule(String start, String end) {
    final now = TimeOfDay.now();
    final startTime = _parseTimeOfDay(start);
    final endTime = _parseTimeOfDay(end);

    if (startTime == null || endTime == null) {
      return true;
    }

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    }

    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Sign Up
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await user.updateDisplayName(fullName);

      final appUser = AppUser(
        uid: user.uid,
        fullName: fullName,
        email: email,
        isPremium: false,
        isSuperUser: false,
        pinLimit: 5,
        chatEnabled: true,
        chatScheduleEnabled: false,
        chatAvailableFrom: '08:00',
        chatAvailableTo: '22:00',
        photoUrl: null,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Login
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      } else {
        throw Exception('User data not found in database.');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Logout
  Future<void> logout() => _auth.signOut();

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  // Error handling
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
