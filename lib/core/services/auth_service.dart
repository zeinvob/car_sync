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
      print("🔄 Attempting login for: $email");

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Check if email is verified
      if (user != null) {
        // Reload to get latest emailVerified status
        await user.reload();
        user = _auth.currentUser;

        if (user != null && !user.emailVerified) {
          print("Email not verified: $email");
          await _auth.signOut();
          throw Exception('email-not-verified');
        }

        print("Login successful for: ${user?.email}");
        return user; // Return the user on success
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code}");
      throw e; // Re-throw to be handled by UI
    } catch (e) {
      print("Unexpected error: $e");
      throw e;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print("Verification email resent to: ${user.email}");
      } else if (user == null) {
        throw Exception('No user is currently signed in');
      } else {
        throw Exception('Email is already verified');
      }
    } catch (e) {
      print("Error resending verification: $e");
      throw e;
    }
  }

  // MARK: - Check Email Verification Status
  Future<bool> checkEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;

        bool isVerified = user?.emailVerified ?? false;

        // Update Firestore if verification status changed
        if (isVerified && user != null) {
          await _storageService.updateEmailVerified(user.uid, true);
        }

        print("Email verified: $isVerified");
        return isVerified;
      }
      return false;
    } catch (e) {
      print("Error checking verification: $e");
      return false;
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
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(fullName);

        // SEND EMAIL VERIFICATION
        await user.sendEmailVerification();
        print("Verification email sent to: $email");

        // Save user data to Firestore
        try {
          await _storageService.saveUserData(
            uid: user.uid,
            email: email,
            fullName: fullName,
            phone: phone,
            dateOfBirth: dateOfBirth,
            emailVerified: false, // Track verification status
          );
          print("User data saved to Firestore");
        } catch (storageError) {
          print("Warning: User created but data not saved: $storageError");
        }

        // Sign out so user must verify before logging in
        await _auth.signOut();
        print("User signed out - must verify email before login");

        return user;
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
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Please login instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Error: ${error.message}';
      }
    } else if (error.toString().contains('email-not-verified')) {
      return 'Please verify your email before logging in. Check your inbox.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

 Future<User?> customerSignUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(fullName);

        // Send email verification
        await user.sendEmailVerification();
        print("Verification email sent to: $email");

        // Save user data with CUSTOMER role
        try {
          await _storageService.saveCustomerData(
            uid: user.uid,
            email: email,
            fullName: fullName,
            phone: phone,
            dateOfBirth: dateOfBirth,
            emailVerified: false,
          );
          print("Customer data saved to Firestore");
        } catch (storageError) {
          print("Warning: User created but data not saved: $storageError");
        }

        // Sign out so user must verify before logging in
        await _auth.signOut();
        print("Customer signed out - must verify email before login");

        return user;
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

  // Get current user role from Firestore
  Future<String?> getCurrentUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        Map<String, dynamic>? userData = await _storageService.getUserData(user.uid);
        return userData?['role'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    String? role = await getCurrentUserRole();
    return role == 'admin';
  }

  // Check if current user is foreman
  Future<bool> isCurrentUserForeman() async {
    String? role = await getCurrentUserRole();
    return role == 'foreman';
  }

  // Check if current user is customer
  Future<bool> isCurrentUserCustomer() async {
    String? role = await getCurrentUserRole();
    return role == 'customer';
  }

  // Admin: Create foreman account
  Future<void> createForemanAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    List<String> assignedSites = const [],
  }) async {
    try {
      // Check if current user is admin
      if (!await isCurrentUserAdmin()) {
        throw Exception('Only admins can create foreman accounts');
      }

      // Create foreman in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(fullName);

        // Save foreman data with role
        await _storageService.createForemanAccount(
          uid: user.uid,
          email: email,
          fullName: fullName,
          phone: phone,
          createdBy: _auth.currentUser!.uid,
          assignedSites: assignedSites,
        );

        print("Foreman account created successfully");
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("Error creating foreman: $e");
      throw e;
    }
  }

  // Admin: Get all foremen
  Future<List<Map<String, dynamic>>> getAllForemen() async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw Exception('Only admins can view foremen');
      }
      return await _storageService.getAllForemen();
    } catch (e) {
      print("Error getting foremen: $e");
      return [];
    }
  }

  // Admin: Update foreman assignments
  Future<void> updateForemanSites({
    required String foremanUid,
    required List<String> assignedSites,
  }) async {
    try {
      if (!await isCurrentUserAdmin()) {
        throw Exception('Only admins can update foreman assignments');
      }
      await _storageService.updateForemanSites(
        uid: foremanUid,
        assignedSites: assignedSites,
      );
    } catch (e) {
      print("Error updating foreman sites: $e");
      throw e;
    }
  }

  // MARK: - Getters
  bool get isUserLoggedIn => _auth.currentUser != null;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserDisplayName => _auth.currentUser?.displayName;
  bool get isCurrentUserVerified => _auth.currentUser?.emailVerified ?? false;
}
