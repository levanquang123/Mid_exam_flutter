import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthFailure implements Exception {
  AuthFailure({
    required this.code,
    required this.message,
    this.rawMessage,
  });

  final String code;
  final String message;
  final String? rawMessage;

  @override
  String toString() {
    return 'AuthFailure(code: $code, message: $message, rawMessage: $rawMessage)';
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'FirebaseAuth login error -> code: ${e.code}, message: ${e.message}, email: ${email.trim()}',
      );
      throw AuthFailure(
        code: e.code,
        message: _mapAuthError(e),
        rawMessage: e.message,
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email format is invalid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase Authentication.';
      case 'network-request-failed':
        return 'Network error. Please check internet connection.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }
}
