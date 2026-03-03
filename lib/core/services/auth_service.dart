import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:car_sync/core/services/storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final StorageService _storageService = StorageService();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email & password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print(
        "FirebaseAuthException in signInWithEmail: ${e.code} - ${e.message}",
      );
      // Re-throw to be handled by the UI
      throw e;
    } catch (e) {
      print("Unexpected error in signInWithEmail: $e");
      throw Exception('An unexpected error occurred');
    }
  }

  // Sign up
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      // STEP 1: Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // update display name
        await user.updateDisplayName(fullName);

        try {
          await _storageService.saveUserData(
            uid: user.uid,
            email: email,
            fullName: fullName,
            phone: phone,
            dateOfBirth: dateOfBirth,
          );
          print("User data saved to Firestore");
        } catch (storageError) {
          // Storage failed but Auth succeeded
          print(
            "Warning: User created but data not saved to Firestore: $storageError",
          );
        }
        await user.reload();
        print("User created successfully in Auth: ${user.uid}");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Unexpected error: $e");
      throw Exception('An unexpected error occurred');
    }
  }

  // Google Sign-In (modern)

  // Sign out
  Future<void> signOut() async {
    try {
      if (_auth.currentUser != null) {
        print("👤 Current user: ${_auth.currentUser?.email}");

        // sign out from Firebase
        await _auth.signOut();

        // sign out from Google
        await _googleSignIn.signOut();

        print("Sign out successful");

        // verify sign out was successful
        assert(_auth.currentUser == null, "User should be null after sign out");
      } else {
        print("No user was logged in");
      }
    } catch (e) {
      print("Sign out error: $e");
      rethrow;
    }
  }

  //reset password
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Re-throw with the error code for handling in the UI
      rethrow;
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  // Firebase exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
