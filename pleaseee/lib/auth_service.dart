import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '773072036609-e6avuo4jqq9ha071abq4u0jn3la7q1u3.apps.googleusercontent.com'
        : null,
  );

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google sign-in error: $e");
      rethrow;
    }
  }
}