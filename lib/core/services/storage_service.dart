import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Save customer data (for self-registration)
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
      throw e;
    }
  }

  // Create foreman account (admin only)
  Future<void> createForemanAccount({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String createdBy,
    List<String> assignedSites = const [],
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'role': 'foreman',
        'createdBy': createdBy,
        'assignedSites': assignedSites,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Foreman account created for UID: $uid");
    } catch (e) {
      print("Error creating foreman: $e");
      throw e;
    }
  }

  // Get user role
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

  // Get all foremen (admin only)
  Future<List<Map<String, dynamic>>> getAllForemen() async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .where('role', isEqualTo: 'foreman')
          .get();
      
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print("Error getting foremen: $e");
      return [];
    }
  }

  // Update foreman assigned sites
  Future<void> updateForemanSites({
    required String uid,
    required List<String> assignedSites,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'assignedSites': assignedSites,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Foreman sites updated for UID: $uid");
    } catch (e) {
      print("Error updating foreman sites: $e");
      throw e;
    }
  }

  // Save user data (your existing method - keep for backward compatibility)
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
      throw e;
    }
  }

  // Update email verification status
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

  // Get user data
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

      await _usersCollection.doc(uid).update(updates);
      print("User data updated for UID: $uid");
    } catch (e) {
      print("Error updating user data: $e");
      throw e;
    }
  }
}