import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Save user data to Firestore after sign up
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required bool emailVerified,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'emailVerified': emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("User data saved for UID: $uid");
    } catch (e) {
      print("Error saving user data: $e");
      throw e;
    }
  }

  Future<void> updateEmailVerified(String uid, bool verified) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'emailVerified': verified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Email verification status updated for UID: $uid");
    } catch (e) {
      print("Error updating email verification: $e");
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData({
    required String uid,
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
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

      await _firestore.collection('users').doc(uid).update(updates);
      print("User data updated for UID: $uid");
    } catch (e) {
      print("Error updating user data: $e");
      throw e;
    }
  }
}
