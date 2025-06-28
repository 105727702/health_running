import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Add this to help with debugging
    signInOption: SignInOption.standard,
  );
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Clear any existing sign-in state
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        // ignore: avoid_print
        print('Google Sign-In: User canceled the sign-in');
        return null;
      }

      // ignore: avoid_print
      print('Google Sign-In: Got Google user: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        // ignore: avoid_print
        print('Google Sign-In: Missing access token or ID token');
        return null;
      }

      // ignore: avoid_print
      print('Google Sign-In: Got authentication tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ignore: avoid_print
      print('Google Sign-In: Created Firebase credential');

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // ignore: avoid_print
      print('Google Sign-In: Successfully signed in to Firebase');
      return userCredential;
    } catch (e) {
      // ignore: avoid_print
      print('Error signing in with Google: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('Error signing out: $e');
    }
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  static bool isSignedIn() {
    return _auth.currentUser != null;
  }
}
