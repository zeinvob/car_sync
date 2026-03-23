import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TechnicianService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get real-time stream of bookings for the workshop
  /// This helps the technician see new jobs immediately
  Stream<QuerySnapshot> getTechnicianJobs() {
    return _firestore
        .collection('bookings')
        .orderBy('bookingDate', descending: true)
        .snapshots();
  }

  /// Add a repair update (text log) to a specific job
  /// This creates a timeline of work for the customer to see
  Future<void> addRepairUpdate({
    required String bookingId,
    required String title,
    required String description,
    String type = 'update',
  }) async {
    try {
      final user = _auth.currentUser;
      
      // 1. Add the update to the sub-collection
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .collection('repairUpdates')
          .add({
        'title': title,
        'description': description,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'technicianId': user?.uid,
      });

      // 2. Automatically update the main booking status to 'in_progress'
      // if the technician has started adding updates.
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error adding repair update: $e");
      rethrow;
    }
  }

  /// Mark a specific job as fully completed
  Future<void> completeJob(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Add a final timeline entry
      await addRepairUpdate(
        bookingId: bookingId,
        title: "Service Completed",
        description: "Your vehicle is ready for pickup.",
        type: "repair",
      );
    } catch (e) {
      debugPrint("Error completing job: $e");
      rethrow;
    }
  }
}