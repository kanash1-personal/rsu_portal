// lib/services/firebase_service.dart
// Firebase Auth only — all data is stored in SQLite via DatabaseService.

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<String?> reauthenticate(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return 'Not signed in.';
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Re-authentication failed.';
    }
  }
}
