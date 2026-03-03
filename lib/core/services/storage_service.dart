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
  }) async {
    try {

      await _usersCollection.doc(uid).set({
        'uid': uid,                 // for easy queries
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print("User data saved with document ID: $uid");
    } catch (e) {
      print("Error saving user data: $e");
      throw Exception('Failed to save user data: $e');
    }
  }
}