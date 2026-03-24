import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for user-related Firestore operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("Error checking user existence: $e");
      return false;
    }
  }

  /// Save Google user data (minimal data - no phone/dob)
  Future<void> saveGoogleUserData({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    try {
      final docRef = _usersCollection.doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': uid,
          'email': email,
          'fullName': fullName,
          'role': 'customer',
          'emailVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'uid': uid,
          'email': email,
          'fullName': fullName,
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print("Google user data saved/updated for UID: $uid");
    } catch (e) {
      print("Error saving Google user data: $e");
      rethrow;
    }
  }

  /// Check if Google user has complete profile (has phone and dateOfBirth)
  Future<bool> needsProfileCompletion(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool hasPhone =
            data.containsKey('phone') &&
            data['phone'] != null &&
            data['phone'].toString().isNotEmpty;
        bool hasDob =
            data.containsKey('dateOfBirth') && data['dateOfBirth'] != null;

        return !hasPhone || !hasDob;
      }
      return true;
    } catch (e) {
      print("Error checking profile completion: $e");
      return true;
    }
  }

  /// Complete profile with phone and date of birth
  Future<void> completeUserProfile({
    required String uid,
    required String phone,
    required DateTime dateOfBirth,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User profile completed for UID: $uid");
    } catch (e) {
      print("Error completing user profile: $e");
      rethrow;
    }
  }

  /// Save customer data (for self-registration)
  Future<void> saveCustomerData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'role': 'customer',
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Customer data saved for UID: $uid");
    } catch (e) {
      print("Error saving customer data: $e");
      rethrow;
    }
  }

  /// Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  /// Save user data (backward compatibility)
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'role': 'customer',
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User data saved for UID: $uid");
    } catch (e) {
      print("Error saving user data: $e");
      rethrow;
    }
  }

  /// Update email verification status
  Future<void> updateEmailVerified(String uid, bool verified) async {
    try {
      await _usersCollection.doc(uid).update({
        'emailVerified': verified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Email verification status updated for UID: $uid");
    } catch (e) {
      print("Error updating email verification: $e");
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

/// Update user data / profile
Future<void> updateUserData({
  required String uid,
  String? fullName,
  String? phone,
  DateTime? dateOfBirth,
  String? profileImageUrl,
}) async {
  try {
    Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (dateOfBirth != null) {
      updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
    }
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

    await _usersCollection.doc(uid).update(updates);
    print("User data updated for UID: $uid");
  } catch (e) {
    print("Error updating user data: $e");
    rethrow;
  }
}
}
