import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
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

      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
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
