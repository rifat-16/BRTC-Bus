import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of Auth status changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current logged in user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google with Native Web Popup Support & Silent Cancel Handling
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Native Official Firebase Google Sign-In Popup for Flutter Web
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Native Google Sign-In for Android & iOS
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      // User intentionally closed or cancelled Google Popup Window -> Return null silently
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'user-cancelled' ||
          e.code == 'cancelled' ||
          e.code == 'canceled') {
        return null;
      }
      rethrow;
    } catch (e) {
      if (e.toString().contains('popup-closed-by-user') ||
          e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        return null;
      }
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _auth.signOut();
  }
}
